## Goal
Populate the final page's left-hand Guild Shop region with unlimited requisitions as a **Spellbook-style, paginated two-column grid of `ShopEntry` objects**.

Authoritative plan: `.docs/RPE2-Final-Guild-Requisitions-Page-Implementation-Plan.md`.

Depends on: #37, #39, #40

This task implements the Guild Shop only. The right-hand limited Requisitions scroll panel is Task 5.

## Primary files
- `client/character/guild/page_GuildRequisitions.lua`

## Source data
Use the assigned RPE Guild Rank's existing:

```lua
rank.requisitions
```

Partition entries by the Task 0 contract:

```text
characterLimit == 0 -> Guild Shop
characterLimit > 0  -> limited Requisitions panel
```

Do not add or consume a second `shop` collection.

If the assigned rank is invalid/unavailable, the Guild Shop should simply have no visible entries. Do not display explanatory empty-state prose.

## Spellbook-style fixed grid
Follow the existing Profile Spellbook's fixed-entry-pool/pagination pattern rather than using `ScrollLayout`.

Define page/grid constants near the top of the page, conceptually:

```lua
local SHOP_COLUMNS = 2
local SHOP_ROWS = 7
local SHOP_ENTRIES_PER_PAGE = SHOP_COLUMNS * SHOP_ROWS
```

Use:

```lua
UI.GridLayoutGroup
```

with exactly two columns.

Create a fixed pool of `UI.ShopEntry` objects for `SHOP_ENTRIES_PER_PAGE` slots. Do not create/destroy an arbitrary number of entry frames every refresh.

The layout must remain driven by the available Guild Shop host width from Task 3 so both columns size consistently.

## Pagination model
Maintain page state conceptually equivalent to:

```lua
self.CurrentShopPage = 1
```

Implement focused helpers following the Spellbook pattern:

```text
get page count
slice current page rows
clamp current page
populate fixed entry pool
hide unused slots
update pagination controls
```

When the shop data set changes and the current page is now out of range, clamp it to the last valid page. With no shop rows, keep internal page state safe and hide all entries.

## Pagination controls
At the bottom of the Guild Shop region, use a `HorizontalLayoutGroup` containing:

- Previous button;
- page indicator;
- Next button.

Use the existing RPE button/text style and the Spellbook's concise interaction pattern.

A suitable indicator is:

```text
Page 1 / 3
```

This is functional pagination UI, not a section heading/help label.

Requirements:

- Previous disabled on first/no page;
- Next disabled on last/no page;
- changing page refreshes only the shop entry binding where practical;
- page controls do not trigger requisition purchases.

Do **not** use `UI.PaginatedPanel` if doing so would produce a different visual layout/control structure than the current Spellbook; mirror the actual Spellbook pattern after inspection.

## ShopEntry binding
For each visible unlimited requisition:

1. resolve the Item definition/reference through the existing Registry API;
2. resolve item display name;
3. resolve item icon with question-mark fallback;
4. format compact cost text;
5. set `ShopEntry` icon/name/cost;
6. evaluate current eligibility through `Guild:GetRequisitionEligibility(...)`;
7. apply available/disabled visual state;
8. bind left click directly to the central `Guild:TryRequisition(...)` transaction;
9. refresh page/shop state after the transaction attempt.

There is no selected-row state and no separate Requisition/Purchase button.

The transaction layer is authoritative. UI disabling is presentation only; the click handler should still rely on `TryRequisition()` rather than duplicating eligibility business rules.

## Compact cost formatting
Create/reuse one page-level helper that can also be consumed by Task 5.

For each requisition cost:

- resolve Currency display name through existing Profile definition APIs;
- include the configured amount;
- combine multiple costs in deterministic authored order;
- do not prepend `Cost:`;
- use a concise one-line format suitable for `ShopEntry:SetCostText(...)`.

Example shapes:

```text
12 Guild Marks
2 Marks, 50 Silver
```

If a Currency definition is unresolved, render a safe compact fallback rather than throw.

`ShopEntry` owns visual truncation/containment; this helper owns semantic cost-string construction.

## Item/requisition tooltip
Use existing tooltip support where useful to expose the full item name/cost details that may be visually truncated. Do not add visible help text to the page.

At minimum, ensure the full item name remains available to any tooltip builder rather than reading the ellipsized display string back from the prefab.

Do not invent a second tooltip system.

## Entry state after purchase
Unlimited entries remain present after a successful purchase.

After refresh:

- if the player can still afford/is otherwise eligible, the entry remains enabled;
- if no longer affordable/eligible, the entry remains visible but becomes disabled/subdued;
- no usage counter should hide/remove it because Task 0 makes unlimited entries ledger-free.

## Layout requirements
- exactly two Guild Shop columns;
- rows laid out by `GridLayoutGroup`, not manual per-entry coordinates;
- item name is top text row and cost is directly underneath via `ShopEntry`;
- long item names rely on Task 2 ellipsis behavior and must never overlap the adjacent column;
- shop region uses approximately the 70% lower-content width established by Task 3.

## Constraints
- Do not use `ScrollLayout` for the Guild Shop.
- Do not implement the right-hand limited Requisition list here.
- Do not reintroduce selection/action/status controls from the provisional UI.
- Do not add `Guild Shop` heading/help/empty-state text.
- Do not duplicate Item/Currency transaction logic.
- Do not modify `ShopEntry` unless a concrete bug against Task 2's contract is found; keep any fix narrow and report it.
- Do not change Daily Reward behavior.

## Acceptance criteria
- [ ] Only `characterLimit == 0` requisitions appear in the Guild Shop.
- [ ] Guild Shop uses a `GridLayoutGroup` with exactly two columns.
- [ ] Shop uses a fixed `ShopEntry` pool rather than a scrolling/dynamically recreated list.
- [ ] Default page capacity is `2 x 7 = 14` entries with constants easy to tune.
- [ ] Pagination slices the unlimited requisition collection deterministically.
- [ ] Previous/Next/page indicator behave correctly at boundaries and with zero rows.
- [ ] Every visible entry shows item icon, name, and cost underneath the name.
- [ ] Long names do not overlap the adjacent column.
- [ ] Compact cost formatting is shared/reusable for Task 5 and has no `Cost:` prefix.
- [ ] Clicking an eligible entry calls the existing `TryRequisition()` path directly.
- [ ] Successful purchase refreshes current affordability/state.
- [ ] Unlimited entries remain visible and repeatedly purchasable while eligible/affordable.
- [ ] Disabled/unaffordable entries remain visible rather than disappearing.
- [ ] No selection state, separate purchase button, section heading or help/empty-state text exists.

## Coding-agent instructions
Read `.docs/RPE2-Final-Guild-Requisitions-Page-Implementation-Plan.md` and completed Tasks #37, #39 and #40. Inspect `client/character/profile/page_ProfileSpellbook.lua` carefully for fixed-entry pool, grid sizing and pagination behavior; also inspect `GridLayoutGroup.lua`, `ShopEntry.lua`, current Registry Item resolution, Profile Currency resolution and Guild requisition eligibility/transaction APIs. Implement Task 4 only. Make the left panel look and behave like a two-column Spellbook of purchasable ShopEntries, not a generic paginated list. Review every acceptance criterion and report changed files, validation performed, and any deviation.