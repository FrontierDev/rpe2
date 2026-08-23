## Goal
Update the existing read-only Guild window to use the revised assigned-rank model before any transactions are enabled.

Depends on: #11, #12, #13

## Primary files
- `client/character/guild/window_Guild.lua`
- `client/character/guild/page_GuildRequisitions.lua`
- `client/character/guild/page_GuildProgression.lua`
- `client/character/guild/page_GuildAdmin.lua`
- `client/client_Guild.lua` only for small facade support required by the pages

## Guild window behavior
Show the local assignment status prominently, for example:

```text
Guild Rank: Medic
Guild Rank: Not assigned
Guild Rank: Medic (no longer valid for current WoW rank)
```

Use the explicit assigned-rank status from the Guild facade. Viewing/refreshing the Guild window must never mutate the Profile assignment.

Remove the old Phase 1 UX that reports multiple active Guild Settings as a conflict. Multiple applicable RPE Guild Ranks are expected under the revised model.

## Requisitions tab
Display only the Requisitions and Daily Rewards belonging to the character's **valid assigned RPE Guild Rank**.

If no valid rank is assigned, show a clean explanatory state and no active transaction controls.

Remove any displayed:

```text
Minimum Guild Rank
```

field derived from legacy `requiredGuildRankIndex`.

This task remains display-only: do not enable purchasing or Daily Reward claiming.

## Progression tab
Display only the Progression definition belonging to the character's valid assigned RPE Guild Rank.

Remain read-only in this task. Do not unlock entries, select spells or write Profile progression state.

## Admin tab
Continue to show the live WoW guild roster and centralized WoW officer gating.

Add read-only/planned presentation for the selected member's RPE Guild Rank where useful, but do not implement remote member query/assignment yet.

## Navigation and refresh
Preserve:
- Launcher -> Guild;
- `/rpe guild`;
- the existing top-level Guild `UI.Window`;
- Requisitions / Progression / Admin tabs;
- Runtime-driven guild roster/window refresh.

## Constraints
- Do not add Requisition purchase behavior.
- Do not grant Daily Rewards.
- Do not write assigned rank state.
- Do not write Progression state.
- Do not add Guild Admin Comms operations yet.
- Do not reintroduce single-setting conflict semantics.

## Acceptance criteria
- [ ] Guild window still opens from Launcher and `/rpe guild`.
- [ ] All three tabs still render.
- [ ] Local assigned Guild Rank is displayed.
- [ ] Unassigned state is clear.
- [ ] Invalid assignment state is clear and does not mutate Profile.
- [ ] Requisitions/Daily Rewards displayed come only from the valid assigned rank.
- [ ] Progression displayed comes only from the valid assigned rank.
- [ ] Multiple catalogue ranks do not show a conflict error.
- [ ] Admin roster still refreshes on guild events.
- [ ] No purchases, reward grants, assignment writes or progression writes occur.

## Coding-agent instructions
Read the revised PDD and implementation plan, then inspect the completed Phase 1 Guild window/pages before editing. Implement Task 5 only. Reuse the Guild facade rather than duplicating catalogue/status logic in individual pages. Report changed files, validation performed and any deviation from this issue.