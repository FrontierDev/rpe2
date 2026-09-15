## Summary

Add a **Traits** page to the Setup Wizard on `dev` using the newly refactored race/class trait model.

The page should let the player review the traits granted by their draft Race/Class selection and choose their starting **class talents** before finalizing setup.

This must use the new ownership semantics:

- racial traits are always granted by the selected race;
- class passives are always granted by the selected class;
- class talents are opt-in and limited by the active ruleset/starting level;
- equipment/consumable traits are unrelated to this page.

The Setup Wizard is a staged editor: race/class/item/skill choices are held in local draft state and are not committed until Apply. Trait selection must follow the same pattern. Do **not** mutate the live profile when the player clicks talents inside the wizard.

## Placement and flow

Insert a new **Traits** tab immediately after **Identity**:

1. Identity
2. Traits
3. Items
4. Skills (when enabled)
5. Action Bar
6. Finalize

The current Setup Wizard uses hard-coded tab indices (`SKILLS_TAB_INDEX = 3`, index-specific refresh logic, page-frame lookups, etc.). Refactor these into explicit named/index constants or otherwise update all affected call paths so adding the Traits page cannot cause the wrong page to build/refresh.

Review at minimum:

- tab definitions in `client/ui/windows/window_SetupWizard.lua`;
- `RefreshPage` and its context array;
- `QueuePageRefresh` / tab-selection callbacks;
- `ApplySkillsPageVisibility`;
- lazy page-frame lookup/build logic;
- any hard-coded Finalize/Action Bar page indices.

## Draft trait state

Extend the Setup Wizard instance state with a draft selection for class talents, e.g.:

```lua
selectedClassTalentLookup = {}
```

The draft should be initialized from the current profile when the wizard opens.

`CaptureSelectionState`, `SyncSelectionState`, and `CollectCurrentSelection` should include the currently selected class talent refs so reopening the wizard faithfully represents the profile's existing selection.

### Race/Class changes

Trait availability is determined from the wizard's **draft** identity selections (`selectedRaceRef` / `selectedClassRef`), not necessarily the currently committed profile identity.

When the draft race changes:

- refresh the racial-passive section immediately.

When the draft class changes:

- refresh class passives immediately;
- refresh the available class talent pool immediately;
- remove/prune draft-selected talents that do not belong to the newly selected class;
- do not alter the live profile until Apply.

Do not call `Profile.ToggleTraitActivation()` directly from the wizard while editing, because that API acts on the committed profile and its currently selected class.

## Page contents

The Traits page should contain three logical sections.

### Racial Passives

Resolve the draft selected Race and display every trait in its `traitRefs` collection.

Requirements:

- informational only;
- always shown as active/granted;
- no checkbox/toggle/action;
- use the standard trait icon/name/tooltip presentation where possible;
- tooltip should identify the trait as granted by the selected race.

If no race is selected, or races are disabled by the active ruleset, show an appropriate empty state rather than stale entries.

### Class Passives

Resolve the draft selected Class and display every trait in its `passiveTraitRefs` collection.

Requirements:

- informational only;
- always shown as active/granted;
- no checkbox/toggle/action;
- use the standard trait icon/name/tooltip presentation where possible;
- tooltip should identify the trait as granted by the selected class.

### Class Talents

Resolve the draft selected Class and display the complete `talentTraitRefs` pool.

Requirements:

- show selected and unselected talents;
- left-click toggles only the wizard's local draft selection;
- selected talents must be visually distinct;
- talents locked by `unlockLevel` at the ruleset starting level must remain visible but disabled/locked;
- locked tooltip/row text must show the required level;
- talent refs from another class must never be selectable;
- missing trait definitions should render safely and must not be selectable.

The UI may reuse the same `UI.SpellbookEntry`/trait tooltip style already used by the Profile Traits page rather than inventing a separate visual language.

## Talent allowance

The page header/summary should show the actual starting class-talent allowance, for example:

```text
Class Talents: 2 / 4 selected
```

or, when the limit is disabled:

```text
Class Talents: 2 selected / Unlimited
```

The allowance must be calculated using the **Setup Wizard starting level** (`GetStartingLevel()`), not the currently committed profile level.

Do not duplicate the talent-limit formula in Setup Wizard code. Factor/reuse a pure Profile/Ruleset helper that can calculate the class talent allowance for an arbitrary level, then use the same helper from both:

- normal Profile trait-count/activation validation;
- Setup Wizard draft validation.

Selecting a talent that would exceed the allowance must fail without mutating draft state and should provide brief feedback.

Racial traits and class passives do not consume class-talent selections.

## Draft trait detail resolution

The current Profile Traits page can rely on the committed profile when building trait rows. The Setup Wizard cannot, because its draft race/class may differ from the live profile.

Do not temporarily mutate the live profile simply to obtain trait details/tooltips.

Instead, resolve the draft Race/Class directly through `Registry` and construct/reuse a side-effect-free trait-detail helper for explicit ownership context, sufficient to provide:

- `traitRef`;
- name/icon;
- payload/description;
- `origin = race|class`;
- `typeCategory = class|talent` as appropriate;
- selected/active state;
- lock state/reason based on the supplied starting level;
- missing-definition state.

Prefer sharing this helper with `BuildProfileTraitRows`/Profile trait detail logic if practical so tooltip/category semantics do not drift.

## Finalize summary

Extend the Finalize page to summarize traits before Apply.

At minimum include:

- race passive count/names where space permits;
- class passive count/names where space permits;
- selected class talents and selected/allowed count.

The summary must use the wizard's draft identity and draft talent selections, not the live profile.

## Applying the wizard

`ApplyCurrentSelection()` currently commits level/race/class and then the remaining setup configuration. Extend this flow so selected class talents are committed **after the class has been set**.

Apply the desired talent set deterministically rather than replaying click/toggle state.

Prefer a canonical Profile API such as:

```lua
Profile.SetSelectedClassTalentTraits(refs)
```

If no equivalent already exists, add one. It should:

- validate every ref against the selected class's `talentTraitRefs`;
- reject/drop locked or invalid refs according to canonical Profile rules;
- enforce the active class talent allowance;
- replace the existing selected class talent set exactly;
- trigger normal configuration/runtime invalidation once the final state is committed.

This avoids the Setup Wizard directly manipulating Database internals or reimplementing the Profile validation layer.

Remember that `Profile.SetClassRef()` now clears selected class talents when the class changes; the wizard should therefore set the class first and then apply its draft class-talent set.

## Page visibility / empty behavior

The Traits tab should be part of the normal Setup Wizard rather than controlled by a new ruleset toggle.

If race/class systems are disabled or the selected definitions contain no traits, retain the page and show useful empty-state text. This avoids another dynamic-tab-index path and keeps the setup sequence predictable.

## Performance

Follow the current lazy page-build pattern used by the Setup Wizard.

Do not rebuild/scan every activated trait dataset on every refresh. Resolve only the refs owned by the current draft Race/Class and cache/reuse row widgets where practical.

The existing Setup Wizard timing instrumentation should include the new page (`SetupWizard.BuildPage` / `SetupWizard.RefreshPage` context `traits`) so any regression is visible at RPE INTERNAL debug level.

## Required validation

Exercise at minimum:

1. Wizard opens on an existing character and reflects the currently selected class talents.
2. Selecting Human shows its racial passives without modifying the live profile before Apply.
3. Selecting a class shows its class passives and entire talent pool.
4. Class passives/racials cannot be toggled.
5. Class talents are inactive/unselected by default when appropriate and can be selected locally.
6. Talent limit is calculated using the ruleset **starting level**.
7. A third talent cannot be selected if the starting allowance is two.
8. Locked higher-level talents are visible but cannot be selected.
9. Switching class removes invalid draft talent selections and immediately displays the new class pool.
10. Switching race immediately updates racial passives.
11. Cancelling/closing the wizard leaves live trait selection unchanged.
12. Applying commits race/class first, then the exact selected class talent set.
13. Reopening the wizard after Apply reproduces the saved talent choices.
14. Skills-tab visibility still works after the tab-index changes.
15. Items, Action Bar and Finalize still refresh the correct pages after the new tab is inserted.
16. Existing equipment and consumable trait behavior is unaffected.

## Acceptance criteria

- Setup Wizard contains a Traits tab directly after Identity.
- The page shows draft racial passives, class passives and the full draft class talent pool.
- Racials/passives are informational and always granted; only class talents are selectable.
- Talent selection is staged locally until Apply.
- Starting-level/ruleset talent limits and unlock levels are enforced.
- Changing draft class/race refreshes the page and cannot leak stale selections.
- Finalize summarizes the trait choices.
- Apply commits an exact, validated class-talent set after class selection.
- Hard-coded Setup Wizard page indices are corrected/refactored so all existing tabs continue working.
- Setup Wizard timing diagnostics cover the new Traits page.