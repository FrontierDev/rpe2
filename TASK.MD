## Goal
Expose the six new Phase 5 Achievement trigger types and their supported filters through the existing Achievement Data Editor.

Depends on: #23

## Primary files
- `client/ui/editor/inspectors/page_InspectorAchievement.lua`
- related Achievement editor helpers discovered by repository inspection

## Trigger dropdown additions
Add user-facing choices:

```text
Item Gain
Skill Gain
RPE Boss Kill
RPE Damage
RPE Healing
RPE Event Started
```

Persist the canonical trigger values introduced by #23:

```text
item_gain
skill_gain
rpe_boss_kill
rpe_damage
rpe_healing
rpe_event_started
```

## Trigger-specific filter controls
Expose only relevant structured fields:

```text
Item Gain
  Item Ref

Skill Gain
  Skill Ref

RPE Boss Kill
  Unit Ref
  Enemy Only

RPE Damage
  Unit Ref
  Enemy Only

RPE Healing
  Unit Ref
  Enemy Only

RPE Event Started
  Event ID
```

Reuse existing RPE Data Editor primitives and current reference/text/check-box conventions. Do not build a new generic reference-editor framework solely for this task.

## Preservation behavior
Changing one criterion's trigger or supported filter must not silently delete:
- that criterion's stable ID;
- unrelated criteria;
- unknown/future filter keys not being edited.

Use the normalized Achievement class as the final data contract rather than implementing a competing editor-only normalizer.

## Constraints
- Do not implement runtime progression hooks.
- Do not modify Profile Achievement state.
- Do not implement Achievement Reward authoring yet.
- Preserve existing General/Criteria editor behavior and export/import.

## Acceptance criteria
- [ ] All six Phase 5 triggers can be authored.
- [ ] Existing five trigger types remain authorable.
- [ ] Appropriate filter controls appear for each new trigger.
- [ ] Stable criterion IDs survive unrelated edits.
- [ ] Unknown filter fields survive unrelated edits/export/import.
- [ ] Existing criterion add/delete/edit behavior remains functional.
- [ ] Editor actions do not mutate Profile Achievement progress.

## Coding-agent instructions
Read the PDD and issue #23, then inspect the current Achievement inspector's trigger list, filter refresh/show-hide logic, commit/normalization flow, and neighboring editor controls before editing. Implement Task 2 only. Preserve stable criterion IDs and unknown filter data; do not introduce runtime hooks or a parallel editor architecture. Review the final diff against every acceptance criterion and report changed files, validation performed, and deviations.