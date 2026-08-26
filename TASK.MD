## Goal
Refactor Inventory presentation so opening/refreshing the window reuses the cached Inventory display snapshot from #62 and updates **only the visible dirty page**, eliminating repeated full Inventory resolution and hidden-page refreshes.

Authoritative documents:

- `.docs/RPE2-Runtime-Performance-Hitch-Elimination-PDD.md`
- `.docs/RPE2-Runtime-Performance-Hitch-Elimination-Implementation-Plan.md`

Depends on: #62

This task owns Inventory window/page presentation only. Do not change item storage/stacking semantics established by #62.

## Primary files

- `client/character/inventory/window_Inventory.lua`
- `client/character/inventory/page_Inventory.lua`
- `client/character/inventory/page_Consumables.lua`
- `client/character/inventory/page_Reagents.lua`
- `core/ui/elements/TabContainer.lua` only if a tiny generic active-tab visibility hook is strictly required
- `core/ui/prefabs/CurrencyPanel.lua` only if revision-aware refresh integration requires a narrow reusable hook

Inspect how the three pages share `InventoryGridPage` behavior before editing.

## 1. Consume one display snapshot per page refresh

`InventoryGridPage:Refresh()` must obtain the current Inventory display snapshot once and pass/reuse it for all computations in that refresh.

Refactor helpers so the same refresh does **not** independently call `Inventory.GetDisplayItems()` through:

```text
GetCategoryDisplayItems
BuildFilterItems
GetFilteredDisplayItems
slot rendering
empty-state calculations
```

Use a flow equivalent to:

```text
snapshot = Inventory.GetDisplayItems()
categoryItems = FilterCategory(snapshot)
filterItems = BuildFilterItems(categoryItems)
visibleItems = ApplySearchAndFilters(categoryItems)
render slots from visibleItems
```

If the Inventory revision changes during the refresh, abort/retry safely rather than mixing two revisions.

## 2. Reuse precomputed snapshot fields

Use the normalized search text, quality, item type, tags, source state and resolved definitions from #62.

Do not rebuild equivalent search strings or repeatedly resolve dataset/item definitions in the page.

Page helpers should treat the snapshot as read-only.

## 3. Refresh only the active Inventory page

`InventoryWindow:Refresh()` currently refreshes every built page.

Change behavior to:

```text
visible active page -> RefreshIfDirty()
hidden built pages -> mark stale/dirty only
unbuilt pages -> no work until first activation
```

Inventory mutation listeners must not render hidden pages.

When a hidden page becomes active, compare its last-rendered relevant revision tuple against current revisions and refresh exactly once if stale.

Preserve lazy tab construction behavior.

## 4. Add page revision/dirty tracking

Each Inventory page must track the revisions/state that affect its rendered content.

At minimum consider:

```text
InventoryRevision
ConfigurationRevision
currency revision if the page displays CurrencyPanel
search query
selected filter values
page/category identity
```

`RefreshIfDirty()` must return immediately when neither the data revisions nor page-local search/filter state changed.

Do not make every currency change rebuild all item filters if only the currency panel needs updating. Prefer a narrower CurrencyPanel refresh when practical.

## 5. Remove duplicate refresh ownership

Audit `Build()`, page builders, `InventoryWindow:Show()`, tab activation callbacks, Inventory change listeners and any `OnShow` handlers.

There must be one clear owner of initial/stale page refresh.

Required lifecycle:

```text
Build -> construct controls only
activate/show page -> RefreshIfDirty once
mutation while visible -> queue/coalesce one refresh
mutation while hidden -> mark dirty only
show unchanged already-rendered window -> visibility/layout work, no full data rebuild
```

Do not leave a Build -> Refresh + Show -> Refresh + OnShow -> Refresh chain.

## 6. Coalesce Inventory UI refresh requests

Consume the consolidated Inventory ChangeSet/listener payload from #62.

Requirements:

- multiple mutations in one outer transaction queue at most one Inventory UI flush;
- if the Inventory window is hidden, do not perform page rendering work;
- if visible, refresh only the active page;
- if a payload identifies a narrow quantity-only change and current sorting/filter membership is unaffected, targeted slot update is allowed but not mandatory;
- a full active-page refresh remains acceptable when membership/order can change, provided it uses the cached snapshot.

Reuse existing TaskQueue/dirty-refresh conventions where practical.

## 7. First construction performance

Keep the current 48-slot pool if #58 timings show construction remains under budget.

If first construction exceeds the PDD’s per-frame hard threshold because of slot creation itself, split **control construction only** into bounded batches without changing page semantics. Do not preemptively complicate construction if profiling does not justify it.

## Acceptance criteria

- [ ] One `InventoryGridPage:Refresh()` consumes one Inventory display snapshot.
- [ ] Page helpers do not repeatedly call `Inventory.GetDisplayItems()` during one refresh.
- [ ] Search/filter logic reuses precomputed snapshot presentation fields.
- [ ] `InventoryWindow:Refresh()` renders only the active page.
- [ ] Hidden built pages become dirty but perform no render work until shown.
- [ ] Unbuilt tabs remain lazy.
- [ ] Reopening unchanged Inventory does not rebuild the display snapshot or refilter the active page unnecessarily.
- [ ] Duplicate Build/Show/OnShow refreshes are removed.
- [ ] Multiple Inventory changes in one transaction queue one UI refresh.
- [ ] Search, filtering, context menus, equip interactions and CurrencyPanel behavior remain correct.

## Validation matrix

```text
open Inventory first time
-> active tab builds
-> one current snapshot consumed
-> hidden tabs do not build/refresh unnecessarily

close and reopen unchanged Inventory
-> cached snapshot reused
-> active page RefreshIfDirty fast-paths

receive one item while Inventory hidden
-> page marked dirty
-> no page render until window shown

receive one item while Inventory visible
-> one UI refresh for active page
-> hidden Consumables/Reagents pages not refreshed

receive 5 reward items in one transaction
-> one Inventory UI refresh request

switch Inventory -> Consumables -> Reagents
-> each stale page refreshes once on activation
-> subsequent unchanged switch fast-paths

change search query
-> active page refilters cached category snapshot
-> no dataset/item re-resolution

change filter selection
-> same

currency-only change
-> CurrencyPanel updates correctly
-> item display/filter snapshot not unnecessarily rebuilt
```

## Constraints

- Do not change Inventory storage/stacking APIs from #62 except for a tiny compatibility fix.
- Do not refresh hidden pages.
- Do not add broad window refresh calls to low-level data mutation code.
- Do not rebuild search text or resolve item definitions already present in the cached snapshot.
- Do not modify unrelated TabContainer behavior unless a minimal reusable hook is proven necessary.
- Preserve current visual layout and feature behavior.

## Coding-agent instructions
Use current `FrontierDev/rpe2` as authoritative. This task is intended for **5.6-Luna-ExtraHigh**. Read both runtime-performance documents and completed #62. Trace the actual refresh call graph from `InventoryWindow:Show()` and Inventory change listeners into each page before editing. Keep the patch presentation-focused. Report the final page lifecycle, revision tuple, number of snapshot fetches per refresh, hidden-page behavior, files changed, and timing results for first/open/reopen with 10/50/150+ stacks.