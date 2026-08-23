## Goal
Activate automatic Achievement progression and completion using the completed Phase 1 Achievement model without coupling it to Guild Rank assignment.

Depends on: completed Phase 1 Achievement data/Profile/editor work. This task may proceed after the Guild Rank foundation is stable; it does not depend on Requisition or Daily Reward runtime.

## Primary files
- `client/client_Achievements.lua` **new** or equivalent focused module
- `core/internal/profile/Achievements.lua`
- `core/internal/profile/Currencies.lua`
- `client/client_Resources.lua`
- current RPE event-completion integration point identified from the repository
- `client/character/profile/page_ProfileAchievements.lua`
- `RPEngine_Dev.toc`

## Trigger contract
Implement the existing Achievement criterion trigger tokens:

```text
manual
currency_gain
rpe_kill
rpe_event_complete
achievement_earned
```

Build an index from Achievement criteria in activated datasets rather than scanning every Achievement/criterion for every runtime event.

Use the Phase 1 stable criterion IDs as the keys for Profile progress.

## Criterion filtering
Apply the Phase 1 filter semantics for the trigger being processed.

At minimum:
- `currency_gain` matches its configured `currencyRef` where present;
- `rpe_kill` respects optional `unitRef` and `enemyOnly` where applicable;
- `achievement_earned` matches configured `achievementRef`;
- `manual` is not advanced by unrelated automatic events;
- `rpe_event_complete` advances only from the authoritative event-completion path.

Do not treat arbitrary filter strings as executable logic.

## Currency gain integration
The correct hook is the positive applied gain path in:

```lua
Profile.AddCurrencyAmount(...)
```

Do not trigger from:

```lua
Profile.SetCurrencyAmount(...)
Profile.SpendCurrencyAmount(...)
```

Calculate:

```text
previousAmount
updatedAmount
actualGain = updatedAmount - previousAmount
```

and only advance `currency_gain` criteria when `actualGain > 0`.

This must respect currency caps; requested gain above the cap counts only the amount actually applied.

## RPE kill integration
Do **not** award kills from preliminary Damage/effect preview.

Use the authoritative committed RPE resource-delta/death path and detect only:

```text
alive before authoritative delta
        ->
dead after authoritative delta
```

Credit the kill only to the correct local player/action owner using the authoritative sender/action context available in the current code.

Repeated updates to an already-dead EventUnit must not produce extra kills.

## Completion behavior
An Achievement completes when all of its criteria meet their goals.

Completion is transition-based:

```text
incomplete -> complete
```

On that transition only:
- persist updated criterion progress;
- set `completedAt` once;
- process `achievement_earned` dependents/meta Achievements;
- refresh Profile Achievements UI;
- announce the newly earned Achievement to Guild/Raid visible chat when appropriate.

Loading an already-completed Profile must never retrigger completion or announcements.

## Manual Grant API
Provide an explicit runtime path such as:

```lua
Achievements:Grant(achievementRef, options)
```

for later Guild Admin use.

`Grant()` must use the normal completion path rather than directly stamping arbitrary Profile state in a way that bypasses completion/meta/UI/announcement handling.

## Broadcasting
Achievement announcements are ordinary visible chat messages, not addon synchronization messages.

When appropriate:
- Guild announcement uses normal Guild chat;
- Raid announcement uses normal Raid chat;
- being in both may announce to both according to the PDD.

## Constraints
- Do not couple Achievement eligibility/progress to RPE Guild Rank.
- Do not add general Guild Admin mutations in this task.
- Do not award from damage previews.
- Do not treat currency spending or absolute Set operations as gain.
- Do not re-announce completed Achievements during load/refresh.
- Preserve Phase 1 Profile state shape and stable criterion IDs.

## Acceptance criteria
- [ ] Currency gain uses actual applied positive delta after cap.
- [ ] Currency spending/absolute set does not count as earning.
- [ ] Kill progression uses authoritative alive->dead transition only.
- [ ] Dead-unit repeats do not count again.
- [ ] Filters select only matching criteria.
- [ ] Meta Achievements progress from `achievement_earned`.
- [ ] `completedAt` is set exactly once per completion transition.
- [ ] Reloading completed state does not announce again.
- [ ] Guild/Raid announcements are visible chat, not addon synchronization.
- [ ] Manual `Grant()` uses normal completion handling.

## Coding-agent instructions
Read the revised PDD and implementation plan, then inspect the current currency, authoritative resource/death and event-completion paths before editing. Implement Task 9 only. Do not guess event authority from preliminary effects. Report changed files, validation performed and any deviation from this issue.