## Goal
Show configured Achievement rewards and their delivery state in the existing Profile -> Achievements UI without making ordinary viewing mutate Achievement state.

Depends on: #31, #32, #33

## Primary files
- `client/character/profile/page_ProfileAchievements.lua`
- `client/client_Achievements.lua` only for read-only presentation helpers and explicit safe retry

## Display requirements
For Achievements with reward definitions/state, show where available:
- reward type;
- resolved Item/Currency name;
- configured amount;
- delivery status;
- delivery/completion/failure timestamp where available;
- failure/recovery reason where useful.

Suggested user-facing states:

```text
Rewards: Pending
Rewards: Received
Rewards: Delivery failed
Rewards: Recovery required
Rewards: Not retroactively granted (legacy completion)
Rewards: Contains unsupported legacy reward data
```

Follow existing Profile Achievements layout patterns rather than creating a second Achievement window.

## Definition resolution
Resolve Item/Currency labels through existing Registry/Profile currency definition APIs. Missing/inactive definitions must render a safe fallback rather than throw or mutate state.

## Retry UI
If #33 exposes a safe explicit retry API, provide `Retry Rewards` only when the persisted state is safely retryable (`failed` after verified rollback).

Do not offer blind retry for:

```text
in-progress
recovery-required
```

unless a later explicit recovery design is added.

Clicking an explicit safe Retry action may mutate state through the runtime API. Merely building/showing/refreshing the page must not.

## Preserve existing Achievement UI
Keep existing:
- tag/category filtering;
- icon/name/description display;
- criterion progress;
- complete/incomplete state;
- completion date;
- read-only ordinary refresh behavior.

## Constraints
- Do not execute rewards automatically from UI refresh.
- Do not mutate raw Profile reward state directly from UI.
- Do not create another Profile/Achievement window.
- Do not add unsupported reward types.

## Acceptance criteria
- [ ] Supported rewards are visible in Profile Achievements.
- [ ] Item/Currency display names resolve where possible with safe fallback.
- [ ] Pending/complete/failed/recovery/legacy states are distinguishable.
- [ ] Ordinary page view/refresh does not mutate Achievement/Profile/Inventory/Currency state.
- [ ] Safe retry is offered only for explicitly safe `failed` state.
- [ ] `in-progress`/`recovery-required` cannot be blindly retried from UI.
- [ ] Existing tag filtering, criterion progress and completion-date UI remain functional.

## Coding-agent instructions
Read issues #31–#33 and inspect the current Profile Achievements page, Registry Item resolution, Profile Currency definition resolution, and reward runtime read/retry APIs before editing. Implement Task 12 only. Keep ordinary UI refresh strictly read-only; route any explicit retry through the central runtime API rather than writing Profile state directly. Review every acceptance criterion and report changed files, validation performed, and deviations.