## Goal

Replace the current tag-derived Achievement categories with an explicit Achievement category model.

Every Achievement must have one built-in top-level category from this fixed list, in this order:

```text
General
Character
Combat
Events
Player vs. Player
Reputation
Feats of Strength
Legacy
```

Achievements may additionally have a **freeform subcategory**, authored as text in the Achievement editor.

Tags remain independent metadata and must no longer define the Profile Achievement category tree.

## Current-code investigation / root cause

### Achievement definition has no category fields

`core/classes/Achievement.lua` currently serializes:

```text
id
name
description
icon
criteria
rewards
tags
```

There is no `category` or `subcategory` field.

### The Data Editor can only author tags

`client/ui/editor/inspectors/page_InspectorAchievement.lua` currently exposes on the General page:

```text
Name
Icon
Tags
Description
```

There is no category selector or subcategory input.

### Profile categories are currently inferred from tags

`client/character/profile/page_ProfileAchievements.lua` copies `achievement.tags` into its row model. `buildCategoryRows()` then collects every unique tag and presents those values as Achievement categories; `filterAchievementRows()` filters by tag.

This is the core model mismatch. A metadata tag such as `seasonal`, `hidden`, or `boss` currently also becomes a first-class navigation category, while there is no way to guarantee the fixed category taxonomy requested for the product.

The original Profile Achievements implementation and current PDD explicitly describe tag-based filters. This issue supersedes that design.

## Required data model

Add explicit normalized fields to `Achievement`:

```lua
Achievement {
    ...
    category = "general",
    subcategory = "",
    tags = {},
}
```

### Stable category keys

Persist stable keys rather than display strings:

```text
general             -> General
character           -> Character
combat              -> Combat
events              -> Events
player_vs_player    -> Player vs. Player
reputation          -> Reputation
feats_of_strength   -> Feats of Strength
legacy              -> Legacy
```

Centralize this key/label/order definition in one Achievement-owned/shared location. The editor and Profile page must consume the same source rather than each defining separate hard-coded lists.

### Defaults and normalization

- `category` defaults to `general` for new and legacy Achievements.
- Unknown/invalid category keys normalize safely to `general` unless there is an existing repository convention for preserving invalid enum values for editor repair; do not allow invalid values to break Profile navigation.
- `subcategory` defaults to `""`.
- `subcategory` is freeform display text; trim leading/trailing whitespace when authored/normalized.
- Blank subcategory is valid and means the Achievement belongs directly to its top-level category.
- Keep case/punctuation as authored after trimming; do not silently rename freeform subcategories.
- Existing `tags` remain normalized exactly as today and are **not migrated into category/subcategory**.

Do not infer an old category from the first tag or otherwise reinterpret legacy tags. Existing Achievements without the new fields simply become `General` while retaining all tags.

## Achievement class / serialization changes

Update `core/classes/Achievement.lua` so:

- `New()` establishes the new defaults;
- `Merge()` accepts and normalizes the fields;
- `ToTable()` serializes both fields;
- import/export round-trips the values;
- existing Achievement criteria/rewards/tags normalization is unchanged.

The current Dataset schema on `main` is `17`. Because this changes the serialized dataset definition shape, bump the Dataset schema to the next version (`18`) using the repository's existing additive normalization convention.

No Profile schema change is required: category/subcategory are definition data, not character progress.

## Data Editor changes

Primary file:

- `client/ui/editor/inspectors/page_InspectorAchievement.lua`

On the General inspector page, add:

```text
Category:     [dropdown]
Subcategory:  [freeform text input]
```

Requirements:

- Category dropdown contains exactly the eight built-in categories in the canonical order above.
- The dropdown stores the stable category key, not the label.
- Subcategory is a normal freeform text input.
- Empty subcategory is allowed.
- Existing Tags input remains available and is clearly independent of category navigation.
- Editing either field uses the normal dataset-entry change/coalescing path.
- Reopening the inspector restores the serialized values correctly.

## Profile -> Achievements category navigation

Primary file:

- `client/character/profile/page_ProfileAchievements.lua`

Replace tag-derived category navigation with the explicit model.

### Top-level rows

The navigation should contain:

```text
All
General
Character
Combat
Events
Player vs. Player
Reputation
Feats of Strength
Legacy
```

The eight built-in category rows must remain in the canonical order, not alphabetical tag order.

`All` remains a synthetic top-level filter and is not persisted into Achievement definitions.

### Subcategory rows

For each built-in category, collect the non-empty `achievement.subcategory` values actually used by active Achievement definitions in that category.

Present them as child/indented rows under their parent category (or the closest existing tree-navigation treatment). Do not create a fake `Other`/`Uncategorized` subcategory for blank values.

Filtering semantics:

```text
select All
-> all active Achievements

select Combat
-> every Achievement with category == combat, regardless of subcategory

select Combat / Raids
-> only category == combat AND subcategory == "Raids"
```

Parent counts should include all Achievements in that category. Child counts should include only the exact subcategory.

Subcategories are definition-driven, not Profile-progress-driven: incomplete and completed Achievements both count.

### Tags

Tags must no longer produce navigation rows or participate in category filtering.

Do not delete tags from the definition model; they may still be useful for runtime/editor metadata or future filters.

## Documentation update

Update the active Achievement sections of:

- `.docs/RPE2-Achievements-Guild-Systems-PDD.md`

The current document still states that Profile Achievements use `tag-based filters` and lists only Tags in the General authoring fields. Replace those statements with the explicit built-in category + freeform subcategory model so future coding work does not restore tag-derived categories.

Do not rewrite unrelated Guild/Achievement runtime sections.

## Primary files

- `core/classes/Achievement.lua`
- `core/internal/database/Database.lua`
- `client/ui/editor/inspectors/page_InspectorAchievement.lua`
- `client/character/profile/page_ProfileAchievements.lua`
- `.docs/RPE2-Achievements-Guild-Systems-PDD.md`

## Acceptance criteria

- [ ] Achievement definitions serialize `category` and `subcategory`.
- [ ] Existing Achievement definitions without the fields load as `General` with a blank subcategory.
- [ ] Existing `tags` are preserved unchanged and are not converted into categories.
- [ ] Category values use stable persisted keys with one centralized key/label/order definition.
- [ ] Dataset schema advances from 17 to 18 through the normal additive normalization path.
- [ ] Achievement editor shows a fixed Category dropdown containing exactly the requested eight categories.
- [ ] Achievement editor shows an editable freeform Subcategory field.
- [ ] Blank subcategory is valid.
- [ ] Category/subcategory survive save, export/import and editor reopen.
- [ ] Profile navigation no longer generates categories from tags.
- [ ] Profile navigation contains All plus the eight built-in categories in canonical order.
- [ ] Selecting a parent category shows all Achievements in that category.
- [ ] Selecting a subcategory filters by both category and subcategory.
- [ ] Subcategories with no active definitions are not emitted as child rows.
- [ ] Blank-subcategory Achievements remain visible when their parent category is selected.
- [ ] Viewing/filtering the Profile page remains read-only and cannot mutate Achievement/Profile state.
- [ ] The active PDD no longer specifies tag-based Achievement categories.

## Validation matrix

```text
load legacy Achievement with tags = {"boss", "seasonal"}
-> category = general
-> subcategory = ""
-> tags remain boss/seasonal
-> no Boss/Seasonal Profile category rows are generated

create Achievement -> Category Combat -> Subcategory Raids
-> stored category = "combat"
-> stored subcategory = "Raids"
-> Profile shows under Combat / Raids

create another Combat Achievement with blank subcategory
-> visible when Combat parent selected
-> no fake child category is created

create Character / Professions and Events / Holidays
-> each appears beneath the correct built-in parent

select All
-> all active definitions shown

select Combat
-> Combat/Raids + blank Combat entries shown

select Combat / Raids
-> only exact Raids entries shown

save/export/import/reopen
-> category/subcategory unchanged

invalid/legacy category key
-> safe normalized General behavior; no navigation error
```

## Constraints

- Do not use tags as a fallback category system after this issue.
- Do not remove the `tags` field.
- Do not store category/subcategory in Profile state.
- Do not create dataset-specific top-level Achievement categories.
- Do not make subcategories a fixed enum; they are intentionally freeform text.
- Do not introduce native Blizzard Achievement IDs/APIs; these remain RPE dataset Achievements.
- Preserve Achievement criteria, completion, rewards and broadcasting semantics.
- Preserve the revision-driven Profile UI lifecycle.

## Coding-agent instructions

Use current `FrontierDev/rpe2` as authoritative. Inspect the current `Achievement` class normalization/serialization, Dataset schema handling, Achievement inspector, and `buildCategoryRows()` / `filterAchievementRows()` in the Profile page before editing. Treat this issue as the authoritative replacement for the old tag-based category design. Keep one canonical category definition consumed by both editor and Profile UI. Report schema behavior, legacy loading behavior, exact files changed, and validation results.