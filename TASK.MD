## Goal
Replace the provisional top-level Guild Requisitions page structure with the final layout shell and implement the complete Daily Reward / Guild Rank / reset-timer header.

Authoritative plan: `.docs/RPE2-Final-Guild-Requisitions-Page-Implementation-Plan.md`.

Depends on: #39

This task establishes the final page hierarchy and header only. The Guild Shop grid and limited Requisitions entry population are implemented in later tasks.

## Primary files
- `client/character/guild/page_GuildRequisitions.lua`

## Final page shell
Use layout groups rather than a manually anchored collection of unrelated controls.

Required hierarchy:

```text
VerticalLayoutGroup — Root
│
├─ HorizontalLayoutGroup — Header
│  ├─ ImageButton — Daily Reward
│  └─ VerticalLayoutGroup — Rank/Reset
│     ├─ Text — Guild Rank
│     └─ Text — Daily Reset countdown
│
└─ HorizontalLayoutGroup — Main Content
   ├─ Guild Shop host region       weight ~7
   └─ Limited Requisition region  weight ~3
```

Create stable host frames/layouts for the two lower regions so Tasks 4 and 5 can populate them without replacing the page architecture again.

Use `HorizontalLayoutGroup`, `VerticalLayoutGroup` and layout weights wherever practical. Manual anchoring should be limited to cases the existing layout abstractions cannot express cleanly.

## Remove provisional top/status presentation
The final page must not retain the current visible status paragraph / Daily Rewards list presentation.

Remove or stop rendering the current concepts equivalent to:

```text
StatusText
DailyPanel
DailyTitle
DailyList
DailyEmptyText
```

Do not replace them with explanatory prose or headings.

The lower provisional requisition selection/action UI may be removed now if the page remains structurally safe for Tasks 4/5; otherwise isolate it clearly for removal in Task 5. Do not add new visible placeholders/headings.

## Daily Reward ImageButton
The upper-left control must be `UI.ImageButton` from `core/ui/elements/ImageButton.lua`.

Use an appropriate square gift/reward icon texture and existing ImageButton highlight/pushed behavior.

Click behavior:

```text
available -> call Client.Guild manual claim API from #38 -> refresh page
claimed   -> do not award again
invalid   -> do not award
pending   -> ignore repeated click while the claim is in progress
```

Do not implement or duplicate reward transactions in the page.

Keep the button hoverable after a claim so the configured reward tooltip remains available. If `SetEnabled(false)` disables mouse hover in the target client, gate claimability in the click handler and apply subdued/claimed visual state without disabling tooltip interaction.

## Daily Reward tooltip
Build the tooltip dynamically from the active assigned Guild Rank / current Daily Reward status.

Required content shape:

```text
Daily Rewards
[icon] Field Ration            x2
[icon] Guild Commendation      x1
```

Use the existing RPE tooltip system (`BaseElement:SetTooltip` / `UI.Tooltip`) and its icon-bearing line support.

For each configured reward:

### Item
Resolve through the existing Registry Item reference API:
- item display name;
- item icon;
- amount.

### Currency
Resolve through existing Profile Currency definition APIs:
- currency display name;
- currency icon;
- amount.

Use the standard question-mark icon fallback when a definition/icon cannot be resolved. Missing definitions must not throw.

The tooltip must remain read-only and must not claim rewards.

## Guild Rank text
To the right of the ImageButton show only:

```text
Guild Rank: <assigned rank name>
```

Resolve through the existing assigned-RPE-Guild-Rank status API.

Do not append daily status prose, eligibility explanations, help text or extra labels.

For invalid/unassigned states, use a concise existing rank fallback only; do not restore the old explanatory status paragraph.

## Reset timer
Directly underneath the rank show:

```text
Daily Reset in HH:MM:SS
```

Consume the centralized reset-state helper from #38. Do not independently calculate a different reset boundary in the page.

Format remaining seconds robustly as hours/minutes/seconds, clamped at zero.

## Visible-page ticker
Start a lightweight one-second ticker while this Requisitions page is visible.

Requirements:

- ticker updates only the timer text during an ordinary tick;
- ticker stops/cancels when the page is hidden;
- reopening the page creates/resumes only one ticker;
- no duplicate ticker accumulation after repeated tab/window show/hide;
- retain the last observed reset-cycle key;
- if the cycle key changes, perform one full `Refresh()` so the Daily Reward claim state updates for the new cycle.

Use existing WoW/RPE ticker patterns if present rather than inventing another task scheduler.

## Refresh contract for header
`RequisitionsPage:Refresh()` should resolve assigned rank and Daily Reward status once per full refresh, then:

1. update rank text;
2. update Daily Reward button claim/visual state;
3. update tooltip source data;
4. update timer text/reset-cycle marker;
5. leave lower host-region population to the later shop/requisition refresh helpers.

Do not perform reward mutation from `Refresh()`.

## No extra visible text
Do not add:

- `Daily Rewards` page heading;
- `Guild Shop` heading;
- `Requisitions` heading;
- instructions;
- empty-state prose;
- eligibility/status paragraphs;
- action-result messages.

`Daily Rewards` is allowed as the **tooltip title**, not as an on-page label.

## Constraints
- Do not implement the two-column Guild Shop entry grid in this task.
- Do not implement limited Requisition `ShopEntry` rows in this task.
- Do not duplicate Daily Reward reset calculations from #38.
- Do not mutate Daily Reward/Profile state during ordinary refresh or tooltip building.
- Do not add a separate tooltip/ticker framework.
- Do not change requisition business rules.

## Acceptance criteria
- [ ] Root page uses a Vertical Layout Group with Header + Main Content.
- [ ] Header uses Horizontal + Vertical layout groups as specified.
- [ ] Lower content has stable approximately 70/30 weighted host regions.
- [ ] Upper-left control is `UI.ImageButton`.
- [ ] Clicking an available reward calls the central manual-claim API exactly once per click/transaction.
- [ ] Claimed/invalid/pending states cannot duplicate a claim.
- [ ] Daily Reward tooltip lists configured Item/Currency rewards with resolved names/icons/amounts and safe fallbacks.
- [ ] Tooltip remains available after claim.
- [ ] Rank renders as `Guild Rank: <name>` without status prose.
- [ ] Reset text renders as `Daily Reset in HH:MM:SS` using #38's reset helper.
- [ ] One-second ticker exists only while visible and does not accumulate duplicates.
- [ ] Reset-cycle change causes one full page refresh.
- [ ] Ordinary header refresh/tooltip build is read-only.
- [ ] Old Daily Rewards list/status paragraph is no longer visible.
- [ ] No new headings/help/empty-state text are added.

## Coding-agent instructions
Read `.docs/RPE2-Final-Guild-Requisitions-Page-Implementation-Plan.md` and completed Tasks #38–#39. Inspect the current `page_GuildRequisitions.lua`, `ImageButton.lua`, `BaseElement.lua`, `Tooltip.lua`, existing ticker lifecycle patterns, assigned Guild Rank display helpers, Registry Item resolution and Profile Currency resolution before editing. Implement Task 3 only. Establish the final page shell/header without prematurely inventing shop/list logic. Review every acceptance criterion and report changed files, validation performed, and any deviation.