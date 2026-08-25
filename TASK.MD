## Goal
Populate the final page's right-hand region with limited/one-time requisitions as a scrolling one-column list of `ShopEntry` rows, then remove the remaining provisional selection/action UI and duplicate Guild Rank window-title text.

Authoritative plan: `.docs/RPE2-Final-Guild-Requisitions-Page-Implementation-Plan.md`.

Depends on: #37, #39, #40, #41

## Primary files
- `client/character/guild/page_GuildRequisitions.lua`
- `client/character/guild/window_Guild.lua`

## Source data
Use the same assigned RPE Guild Rank and the same existing:

```lua
rank.requisitions
```

collection as the Guild Shop.

The right-hand panel contains only:

```text
characterLimit > 0
```

requisitions.

`characterLimit == 0` belongs exclusively to the left-hand Guild Shop implemented by #41.

Do not create a second definition collection.

## ScrollLayout implementation
Use:

```lua
UI.ScrollLayout
```

with:

```lua
rowElementClass = UI.ShopEntry
```

and a single full-width column.

Configure row height/spacing to match the compact `ShopEntry` visual language. Prefer `autoFitRows = true` if that integrates cleanly with the available right-hand host height; otherwise derive a stable visible-row count from the final layout without manual per-row anchoring.

The scrollbar should appear only when required through existing `ScrollLayout` behavior.

Do not paginate the limited Requisitions panel.

## ShopEntry row binding
For each visible limited requisition:

1. resolve the Item definition/reference through the existing Registry API;
2. resolve item display name/icon with safe question-mark fallback;
3. reuse the compact cost formatter introduced by #41;
4. set `ShopEntry` icon/name/cost;
5. evaluate eligibility through `Guild:GetRequisitionEligibility(...)`;
6. keep exhausted/unaffordable/unavailable entries visible but disabled/subdued;
7. bind left click directly to `Guild:TryRequisition(...)`;
8. refresh the page/list after a transaction attempt.

There is no selection state and no separate action button.

For finite limits greater than `1`, the entry remains enabled while usage is below the limit and becomes disabled only when the existing eligibility API reports it exhausted or otherwise unavailable.

Do not make row display logic the authority for usage; the existing Guild/Profile transaction layer remains authoritative.

## Truncation and cost layout
Each right-hand row uses the same `ShopEntry` contract as the Guild Shop:

```text
[icon] Item Name
       Item Cost
```

The item name remains one line and truncates with `...` through `ShopEntry` when the narrow panel width requires it.

Cost appears directly underneath the name and uses the same formatter as #41. Do not add a `Cost:` prefix.

## Empty/invalid state
When there are no limited requisitions, hide/recycle the rows normally and leave the panel visually empty.

Do not render:

- `No requisitions configured`;
- invalid-rank explanation;
- eligibility help;
- status paragraphs;
- a section heading.

## Remove provisional selection/action UI
Delete the remaining old-page state/controls associated with selecting a requisition and pressing a separate action button.

Remove obsolete concepts equivalent to:

```text
SelectedRequisitionIndex
SelectedRequisitionItems (if no longer needed as page partition data)
setSelectedRow(...)
RequisitionButton
RequisitionActionStatus
RequisitionActionMessage
RequisitionPending (unless a new narrow per-click guard is genuinely required)
RequisitionTitle
RequisitionEmptyText
old ScrollListEntry requisition rendering
```

Also remove obsolete helper functions whose only consumer was the provisional selection/action/status UI.

Do not remove reusable item/currency resolution or failure-safe logic that the final binding still uses.

## Final Refresh flow
After this task, `RequisitionsPage:Refresh()` should conceptually:

```text
resolve assigned RPE Guild Rank status
        ↓
resolve Daily Reward status/reset state
        ↓
update header
        ↓
partition rank.requisitions:
  characterLimit == 0 -> Guild Shop rows
  characterLimit > 0  -> limited rows
        ↓
refresh paginated Guild Shop
        ↓
refresh limited ScrollLayout
```

Do not perform requisition mutation during ordinary `Refresh()`.

Do not rebuild/reattach scripts unnecessarily on every refresh if existing row/entry objects can retain stable handlers using bound row data.

## Guild window title cleanup
`client/character/guild/window_Guild.lua` currently appends assigned-RPE-Guild-Rank display text to the window title during refresh.

The final page already shows the rank in its header. Keep the window title simply:

```text
Guild
```

Do not append:

```text
| Guild Rank: ...
```

This cleanup must not change tab construction, page refresh routing, Admin/Progression pages, window dimensions or show/hide behavior.

## Final no-extra-text rule
After this task the Requisitions tab must contain no visible:

- `Guild Shop` heading;
- `Requisitions` heading;
- `Daily Rewards` heading;
- instructions/help text;
- status paragraph;
- empty-state prose;
- purchase/requisition action-result text;
- separate purchase button.

The allowed functional text is limited to things such as:

- `Guild Rank: <name>`;
- `Daily Reset in HH:MM:SS`;
- `ShopEntry` item names/costs;
- shop pagination controls/page indicator.

Tooltip text is not considered an extra on-page label.

## Constraints
- Do not change unlimited Guild Shop pagination from #41.
- Do not change `characterLimit` business semantics from #37.
- Do not implement a separate limited-requisition transaction path.
- Do not add usage counters/labels unless already part of the agreed design (they are not currently required).
- Do not add empty-state/status labels.
- Do not alter Progression/Admin page behavior.
- Do not change Daily Reward business logic.

## Acceptance criteria
- [ ] Only `characterLimit > 0` requisitions appear in the right-hand panel.
- [ ] Right-hand panel uses `UI.ScrollLayout` with `UI.ShopEntry` rows.
- [ ] Right-hand entries are one column/full panel width.
- [ ] Each row shows icon, item name and cost directly underneath.
- [ ] Narrow/long item names truncate with `...` and do not overflow.
- [ ] Cost formatting matches the Guild Shop and has no `Cost:` prefix.
- [ ] Clicking an eligible row calls the existing `TryRequisition()` transaction directly.
- [ ] Limited usage/character-limit behavior remains authoritative and unchanged from #37.
- [ ] Exhausted/unaffordable entries remain visible but disabled/subdued.
- [ ] No pagination is used for the right-hand panel.
- [ ] Old selected-row/separate Requisition button/action-status UI is removed.
- [ ] No visible section headings/help/status/empty-state prose remain on the Requisitions page.
- [ ] `RequisitionsPage:Refresh()` cleanly refreshes header, shop and limited rows without gameplay mutation.
- [ ] Guild window title remains exactly `Guild` during refresh.
- [ ] Progression/Admin tabs and Guild window lifecycle remain unchanged.

## Coding-agent instructions
Read `.docs/RPE2-Final-Guild-Requisitions-Page-Implementation-Plan.md` and completed Tasks #37, #39–#41. Inspect current `ScrollLayout.lua` custom row-class behavior, `ShopEntry.lua`, the page's shared cost/item helpers, `Guild:GetRequisitionEligibility(...)`, `Guild:TryRequisition(...)`, and `window_Guild.lua` refresh/title logic before editing. Implement Task 5 only. Reuse the same ShopEntry and transaction semantics as the left Guild Shop; the only presentation distinction is scrolling one-column limited entries versus paginated two-column unlimited entries. Review every acceptance criterion and report changed files, validation performed, and any deviation.