## Goal

Keep the Profile -> Spellbook category/navigation panel limited to content that the current character can actually display.

An activated dataset with **no known spells for the current Profile** must not appear in the Spellbook navigation, and a spellbook category with no known spells must not appear underneath a dataset.

This is a Profile presentation/filtering fix only. Do not change dataset activation, spellbook persistence, spell learning/forgetting, or spell definition semantics.

## Current-code investigation / root cause

Primary file:

- `client/character/profile/page_ProfileSpellbook.lua`

The current navigation is built in `buildNavigationRows(knownSpells)`.

The function already resolves the Profile's known spells and calculates counts such as:

```text
spellCountsByDataset[datasetId]
category counts per dataset
```

However, after calculating those counts it still iterates **every activated dataset** and unconditionally appends a dataset navigation row, using a fallback count of zero:

```lua
count = spellCountsByDataset[datasetId] or 0
```

As a result, dataset activation is currently being treated as sufficient reason to show a Spellbook navigation entry even when that dataset contributes no spells to this character.

There is a second related issue in the category construction path: category names are also discovered from the dataset's authored `dataset.spells` definitions. That means a category can exist in the navigation merely because the dataset defines a spell with that category, even when the current Profile knows none of those spells.

`EnsureDatasetSelection(rows)` then has to work around the presence of zero-count rows by trying to select a dataset with spells and falling back to the first dataset row. Once zero-content rows are removed, this selection logic also needs to handle the genuinely empty navigation case cleanly.

## Required solution

### 1. Build visibility from the character's known/resolved Spellbook content

Retain the existing known-spell resolution/counting path as the source of truth for the Profile Spellbook UI.

After counts are known, append a dataset navigation row only when:

```text
spellCountsByDataset[datasetId] > 0
```

Do not use the mere presence of an activated dataset as a visibility condition.

This must not deactivate the dataset or affect any other UI/runtime system.

### 2. Do not show empty spellbook categories

A child category should be shown only when the current Profile has at least one visible/known spell in that category for that dataset.

Do not generate visible category rows solely from authored `dataset.spells` definitions.

The implementation may still consult definitions to obtain category metadata, but the final row set must be gated by the **known-spell category count**.

Expected behavior:

```text
Dataset A
  Fire       3 known spells
  Frost      0 known spells

navigation -> Dataset A / Fire
               no Frost row
```

### 3. Fix selection fallback after rows disappear

When the currently selected dataset/category is no longer present because the character forgot/moved/removed its last qualifying spell:

- select the first remaining visible dataset deterministically;
- clear an invalid category selection;
- if no dataset rows remain, clear both `SelectedDatasetId` and `SelectedCategoryKey`;
- leave the main Spellbook list in its existing clean empty state;
- do not retain a hidden selection that causes the visible list/navigation to disagree.

### 4. Preserve existing known-spell semantics

Do not broaden this issue into changing how `resolvedKnownSpells` treats inactive/missing definitions or how spells are learned.

Use the page's existing definition-resolution behavior and change only navigation visibility/selection around that resolved set.

## Primary file

- `client/character/profile/page_ProfileSpellbook.lua`

No schema, SavedVariables, Registry, or dataset-format change should be required.

## Acceptance criteria

- [ ] An activated dataset with zero known Profile spells is absent from the Spellbook navigation.
- [ ] A dataset appears as soon as the Profile has at least one visible/known spell from it.
- [ ] Dataset count equals the number of known spells represented by the page's existing resolution rules.
- [ ] A spellbook category with zero known spells is absent.
- [ ] A category appears when at least one known spell belongs to it.
- [ ] Authored spell definitions alone cannot create an empty category row.
- [ ] Forgetting/removing the last spell from the selected dataset removes that dataset row and moves selection to the first remaining visible dataset.
- [ ] Forgetting/removing the last spell from the selected category clears/moves the category selection without leaving stale UI state.
- [ ] With no known spells from any activated dataset, navigation is empty and the page does not error.
- [ ] Dataset activation/deactivation behavior outside the Profile Spellbook is unchanged.
- [ ] Spell learning/forgetting and Profile persistence are unchanged.

## Validation matrix

```text
3 activated datasets; Profile knows spells only from dataset B
-> navigation shows dataset B only

Profile learns first spell from dataset A
-> dataset A appears with count 1

Dataset A defines Fire/Frost; Profile knows Fire only
-> Fire appears
-> Frost does not appear

Profile learns first Frost spell
-> Frost appears

selected Frost category; Profile forgets last Frost spell
-> Frost row disappears
-> stale category selection is cleared
-> Dataset A remains selected if it still has other spells

selected dataset A; Profile forgets its final known spell
-> dataset A row disappears
-> first remaining visible dataset becomes selected

Profile has no known spells
-> no zero-count dataset/category rows
-> empty content state remains safe

activate dataset containing many spell definitions but learn none
-> it does not appear in Profile Spellbook navigation
```

## Constraints

- Do not change dataset activation rules.
- Do not hide datasets from the Data Editor, Registry, or other Profile tabs.
- Do not change the Profile spellbook data schema.
- Do not create placeholder/disabled zero-count navigation rows.
- Do not infer visibility from all authored spell definitions; use the current character's known-spell content.
- Preserve the revision-driven Profile page lifecycle established by the current runtime-performance work.

## Coding-agent instructions

Use current `FrontierDev/rpe2` as authoritative. Trace `buildNavigationRows()`, `EnsureDatasetSelection()`, the known-spell resolution path, category filtering, and the refresh/revision lifecycle before editing. Keep the patch scoped to Spellbook navigation filtering and stale-selection handling. Report exact functions changed and validate all cases above.