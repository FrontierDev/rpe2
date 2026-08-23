## Goal
Replace the current Achievement placeholder with a functional authoring surface and add the missing Achievement inspector using existing RPE2 Data Editor patterns.

Depends on: Task 1 complete on `main`; #2; #4

## Primary files
- `client/ui/editor/pages/page_Achievement.lua`
- `client/ui/editor/inspectors/page_InspectorAchievement.lua` **new**
- Data Editor mapping/core files that enumerate collections/inspectors/refreshers
- `RPEngine_Dev.toc`

## Required behavior
### Achievement page
Replace the placeholder with a real selectable list/icon list. Each entry should show at least:
- icon;
- name;
- ID or useful secondary detail;
- selection state.

Preserve generic create/select/delete/export/import behavior supplied by the existing Data Editor framework.

### Inspector integration
Add Achievements to every relevant inspector mapping/getter/refresh path. Selecting an Achievement must open its inspector.

### Inspector fields
#### General
- Name
- Description
- Icon
- Tags

#### Criteria
Editable collection supporting:
- add/delete criterion;
- stable Criterion ID;
- Description;
- Trigger dropdown;
- Goal;
- Phase 1 filter fields.

Required filter UI:
- `currency_gain`: `currencyRef`
- `rpe_kill`: optional `unitRef`, optional `enemyOnly`
- `achievement_earned`: `achievementRef`
- `manual`: none required
- `rpe_event_complete`: none required in Phase 1

Use existing reference/dropdown/text-input conventions. Do not build a large new reference-picker framework solely for this task.

#### Rewards
Preserve and round-trip existing `rewards` data, but do not invent reward execution semantics or a speculative reward schema.

## Constraints
- Do not create a separate Achievement editor window.
- Do not add trigger execution or Profile progression logic.
- Editing/reordering one criterion must not change IDs of unaffected criteria.
- Follow current RPE UI abstractions and Data Editor patterns.

## Acceptance criteria
- [ ] New Achievement can be fully authored through Data Editor.
- [ ] Criteria add/delete/edit works with stable IDs.
- [ ] Trigger changes do not corrupt unrelated criterion data.
- [ ] Selection/refresh behaves like neighboring collections.
- [ ] Export/import preserves authored Achievement data.
- [ ] No runtime Achievement behavior is introduced.

## Coding-agent instructions
Search all explicit collection and inspector maps before editing. Make the smallest coherent integration rather than special-casing the editor outside its current architecture.