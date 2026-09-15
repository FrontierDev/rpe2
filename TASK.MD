## Summary

Trait conditions are currently evaluated for display, but a trait that fails those conditions can still be selected/assigned. Fix trait validation so failed validation is authoritative at the Profile API layer and cannot be bypassed by any UI or caller.

Target branch: `dev`.

This is relevant to both the normal Profile Traits page and the new Setup Wizard trait page in #304.

## Current cause

`Profile.GetKnownTraitDetails()` already evaluates trait conditions and stores the result in `conditionFailureText`, but the trait's `isLocked` state currently only reflects the level/unlock requirement.

Conceptually, the current behavior is:

```lua
conditionFailureText = conditionState.passed ~= true and conditionState.failureText or ""
...
detail.isLocked = detail.typeCategory == "talent" and detail.isUnlockedForProfile ~= true
```

This means a trait can visibly fail validation while remaining toggleable/selectable. UI code that only checks `isLocked` therefore still permits assignment, and the underlying activation API does not provide a canonical condition-validation guard.

## Required behavior

A trait that does not currently satisfy its assignment conditions must **not** be assignable/activatable.

This must be enforced in two places:

1. canonical Profile validation/API layer;
2. UI presentation/interactions.

The Profile/API check is authoritative. The UI check is only presentation/usability and must not be the only protection.

## Canonical validation helper

Introduce/refactor a side-effect-free validation helper for a candidate trait, for example:

```lua
Profile.ValidateTraitAssignment(traitRef, options)
```

or equivalent.

It should return structured information, e.g.:

```lua
{
    valid = false,
    reason = "Requires ...",
    code = "condition_failed",
}
```

The validation path should cover every rule that determines whether a selectable/manual/class talent can be assigned, including at minimum:

- trait definition exists;
- trait belongs to the selected class when it is a class talent;
- trait is not a race/class passive being manually assigned;
- unlock level is met;
- trait conditions pass;
- class-talent allowance is not exceeded;
- any existing generic/manual trait-count limits;
- any other current ownership/ruleset restrictions.

Do not duplicate condition logic between UI and mutation functions.

## Condition evaluation context

Use the same condition engine and context semantics already used by trait detail/tooltip evaluation.

For the committed profile path, validation should evaluate against the current profile state.

For callers that need hypothetical/draft state (notably Setup Wizard #304), allow the helper to accept an explicit context/options object rather than temporarily mutating the live profile. This should be sufficient to validate against at least:

- draft level;
- draft race;
- draft class;
- draft selected class talents where needed for count/ownership rules.

Do not make the Setup Wizard implement its own independent condition evaluator.

## Mutation APIs

Update every API that can add/select/activate a selectable trait so it calls the canonical validator before mutating state.

Review at minimum:

- `Profile.ActivateTrait()`;
- `Profile.ToggleTraitActivation()`;
- `Profile.AddKnownTrait()` if still applicable to generic/manual traits;
- the selected-class-talent add/set APIs introduced by #301/#304;
- any direct Database-facing trait mutation wrappers used elsewhere.

A failed validation must:

- return failure;
- leave persisted state unchanged;
- not consume a talent slot/count;
- not trigger a misleading activation refresh as though assignment succeeded.

If practical, return the structured failure reason to the caller so UI can display it.

## Existing selected traits becoming invalid

Do not automatically remove a previously selected trait merely because a transient runtime condition later becomes false unless the condition model explicitly defines that behavior.

This issue concerns **assignment eligibility**: a trait must satisfy its assignment/selection validation when the user attempts to choose it.

If the existing condition system distinguishes assignment-time requirements from runtime effect conditions, preserve that distinction. If it does not, inspect the current condition semantics and ensure this fix does not accidentally disable runtime-only conditional trait effects.

Document the chosen behavior in code/tests.

## Profile Traits UI

Update `client/character/profile/page_ProfileTraits.lua` / `Client:BuildProfileTraitRows()` so a trait that fails assignment validation is visibly unavailable.

Requirements:

- keep the trait visible where appropriate;
- mark it disabled/locked/not selectable;
- left-click must do nothing;
- context-menu Activate must be disabled/omitted;
- tooltip should show the validation failure reason;
- selected traits should still display their current state appropriately if the failure is from a condition that only governs future assignment.

Do not infer availability from `conditionFailureText ~= ""` independently if a canonical validation result is available; use the same validator result as the mutation API.

## Setup Wizard integration (#304)

The Traits page added by #304 must use this same validation helper for draft class talents.

A talent that fails validation under the wizard's draft state must:

- remain visible if it belongs to the selected class;
- show the validation failure reason;
- be visually disabled;
- not enter `selectedClassTalentLookup` when clicked;
- be filtered/rejected again when Apply commits the final talent set.

The final Profile setter used by #304 must revalidate all refs at commit time so stale or externally-invalid draft refs cannot be persisted.

## Regression coverage

Add deterministic tests/mocks covering at minimum:

1. A trait whose condition passes can be assigned.
2. The same trait with the condition failing cannot be assigned.
3. Failed assignment leaves active/selected trait storage unchanged.
4. UI row for a failing trait is non-toggleable and exposes the reason.
5. Directly calling `Profile.ActivateTrait()` cannot bypass validation.
6. Directly calling selected-class-talent add/set APIs cannot bypass validation.
7. Unlock-level failure is also rejected by the same canonical validation path.
8. Cross-class talent assignment is rejected by the same path.
9. Talent-limit overflow is rejected by the same path.
10. Setup Wizard draft validation uses draft level/race/class rather than committed values.
11. Setup Wizard Apply revalidates before persistence.
12. A runtime-only conditional effect is not accidentally treated as an assignment restriction if current condition semantics distinguish those concepts.

## Acceptance criteria

- Any trait that fails assignment validation cannot be assigned or activated.
- Enforcement exists in the Profile mutation layer, not only UI code.
- UI consistently disables unavailable traits and shows why they are unavailable.
- Setup Wizard #304 uses the same validation logic for draft selection and final commit.
- Trait validation rules have one canonical implementation shared by all callers.
- No failed assignment mutates persisted trait state.