## Goal
Fix the Guild Ranks / GuildSetting Data Editor inspector so none of its four pages overflow the inspector viewport.

The following pages must each have a proper vertical scroll view:

- General
- Requisitions
- Daily Rewards
- Progression

The selector bar (`Prev` / page dropdown / `Next`) remains fixed at the top. Only the active page body scrolls.

This is a layout task only. Preserve all GuildSetting schema, authoring behavior, reference selection, normalization, pending dataset-change coalescing, and business semantics.

## Dependency / ordering
Implement this **after #46 or independently of #46**; there is no runtime dependency. However, complete this issue **before the currency-selector follow-up issue** because both tasks edit `client/ui/editor/inspectors/page_InspectorGuildSetting.lua` and this ordering minimizes conflicting rewrites.

## Current source observations

`page_InspectorGuildSetting.lua` currently creates each page as a fixed frame and anchors a `VerticalLayoutGroup` directly to it. Long pages therefore continue growing beyond the visible inspector region.

The repository already has the required scroll-view pattern in inspector implementations such as:

```text
client/ui/editor/inspectors/item/page_InspectorItemEquipment.lua
```

That pattern uses:

- a `ScrollFrame` clipped to the page;
- a vertical scrollbar using existing `scrollbar.track` / `scrollbar.thumb` color tokens;
- an auto-sized vertical layout as the scroll child;
- mouse-wheel support;
- dynamic scroll-range recalculation from content height vs viewport height.

Reuse this established pattern rather than introducing a second visual style.

## Primary file

- `client/ui/editor/inspectors/page_InspectorGuildSetting.lua`

A small reusable local helper inside this file is preferred because all four pages need the same shell. Do not create a new global UI abstraction unless repository inspection shows an existing shared helper already intended for this purpose.

## Required implementation

### 1. Shared GuildSetting page scroll shell
Create or reuse a helper that provides, per GuildSetting inspector page:

```text
Page frame
├─ ScrollFrame
│  └─ auto-sized VerticalLayoutGroup scroll child
└─ vertical scrollbar
```

The helper should handle:

- clipping;
- mouse wheel;
- scrollbar value -> vertical scroll;
- viewport resize -> scroll-child width refresh;
- content/layout refresh -> scroll-range refresh;
- scrollbar visibility/enabled state when content fits without scrolling;
- existing UI color tokens for scrollbar track/thumb.

Avoid duplicating the complete scroll plumbing four times if a local helper can express it cleanly.

### 2. Convert all four pages
Move the existing page contents into the corresponding scroll-child root for:

- `BuildGuildSettingInspectorGeneralPage`
- `BuildGuildSettingInspectorRequisitionsPage`
- `BuildGuildSettingInspectorDailyRewardsPage`
- `BuildGuildSettingInspectorProgressionPage`

The visual field order and existing page selector structure should remain unchanged unless a tiny spacing adjustment is required to avoid clipping against the scrollbar.

### 3. Dynamic content must update scroll range
The Requisitions and Daily Rewards pages contain dynamic/conditional content and nested list sections. Whenever their root layout changes height, the page scroll range must remain correct.

Examples include:

- selecting/deleting requisitions;
- showing/hiding item vs currency Daily Reward fields;
- adding/deleting costs;
- adding/deleting progression entries;
- section panels changing calculated height.

Do not rely only on the initial build-time height.

### 4. Nested scrollable lists
Several GuildSetting pages already contain `UI.ScrollLayout` list controls inside the page.

The outer page scroll view must not break those lists. In particular:

- list rows remain clickable;
- list scrollbar/selection behavior remains functional;
- wheel behavior should be sensible when the cursor is over an inner scrolling list;
- the outer page must still be scrollable when the cursor is over ordinary fields/background.

Follow existing editor behavior where nested scroll regions already exist.

### 5. Page switching
Switching General/Requisitions/Daily Rewards/Progression must continue to show exactly one page.

It is acceptable either to preserve each page's previous scroll position or reset it when changing pages, but behavior must be deterministic and must never leave a newly selected page outside its valid scroll range.

## Acceptance criteria

- [ ] General page is vertically scrollable when its content exceeds the viewport.
- [ ] Requisitions page is vertically scrollable when its content exceeds the viewport.
- [ ] Daily Rewards page is vertically scrollable when its content exceeds the viewport.
- [ ] Progression page is vertically scrollable when its content exceeds the viewport.
- [ ] No GuildSetting page content renders outside the inspector page bounds.
- [ ] Selector bar remains fixed and does not scroll with page contents.
- [ ] Scrollbars use the established editor/UI visual treatment.
- [ ] Content that fits the viewport does not leave a misleading active scrollbar.
- [ ] Dynamic field visibility and section-height changes update the scroll range correctly.
- [ ] Existing nested `UI.ScrollLayout` lists remain usable.
- [ ] All existing field values and editor mutations behave as before.
- [ ] No GuildSetting schema or runtime Guild logic changes are introduced.

## Validation matrix

```text
General page at normal Data Editor size
-> bottom fields reachable by scrolling; nothing overflows page bounds

Requisitions with several entries/costs
-> all controls reachable; inner requisition/cost lists still usable

Daily Rewards item type
-> item fields visible/reachable

Daily Rewards currency type
-> currency fields visible/reachable; scroll range updates after type switch

Progression with entries
-> all progression controls reachable

resize Data Editor shorter/taller
-> scrollbar range updates; content width remains correct

page with content shorter than viewport
-> no unnecessary active scrollbar

switch page after scrolling previous page
-> selected page starts/preserves a valid scroll position, never outside range
```

## Coding-agent instructions
Use current `FrontierDev/rpe2` as authoritative. This task is intended for **5.6-Luna-ExtraHigh**. Before editing, inspect the scroll implementation in `client/ui/editor/inspectors/item/page_InspectorItemEquipment.lua` and any newer reusable inspector-scroll helper in the current branch. Prefer a compact local helper in `page_InspectorGuildSetting.lua` rather than four copy-pasted scroll implementations. Preserve all existing GuildSetting authoring behavior and report exact files changed plus validation performed.