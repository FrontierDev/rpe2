## Goal

Make Profile -> Achievements substantially denser so the Achievement scroll view displays **8 entries at once**, while keeping each card readable.

This is a follow-up to completed #77. It deliberately supersedes #77's earlier visible-card requirement to show criterion/progress presentation.

Required card content:

```text
[icon] Achievement Name
       Description

       completion state/date where retained
       Rewards: <status>          <- centered at bottom
```

Do **not** show criterion summaries or progress bars in the Achievement entry itself.

## Current-code investigation / root cause

### 1. The Profile page is explicitly configured for only three rows

`client/character/profile/page_ProfileAchievements.lua` currently defines:

```lua
local ENTRY_HEIGHT = 78
local ENTRY_SPACING = 4
local ENTRY_ROWS = 3
```

and then uses those values for both the EntryPanel and `UI.ScrollLayout`:

```lua
visibleRows = ENTRY_ROWS,
rowHeight = ENTRY_HEIGHT,
rowSpacing = ENTRY_SPACING,
```

So the list can only bind/show three pooled Achievement rows even when the surrounding Profile content region has much more vertical space.

### 2. `AchievementEntry` reserves height for content that is no longer wanted

`core/ui/prefabs/AchievementEntry.lua` currently allocates:

```text
name
2-line description
progress bar / criterion summary
completion status
reward status
```

with defaults including:

```lua
DEFAULT_HEIGHT = 78
DEFAULT_DESCRIPTION_HEIGHT = 22
DEFAULT_PROGRESS_HEIGHT = 14
DEFAULT_STATUS_HEIGHT = 13
```

`SetLayoutMetrics(...)` always reserves a progress region between the description and status row, even when the progress element is hidden.

The prefab also creates and maintains both:

```lua
self.progressBar
self.criterionElement
```

and `page_ProfileAchievements.lua` computes/binds `buildCriterionPresentation(...)` for every visible card.

### 3. Reward state is currently right-aligned in a split bottom row

The bottom status row is divided into completion and reward regions:

```lua
statusWidth = ~48% of content width
rewardWidth = remaining width
```

and the reward element uses:

```lua
justifyH = "RIGHT"
```

This produces the right-edge `Rewards: Pending` / `Rewards: Delivery failed` presentation shown in-game rather than a centered footer.

## Required solution

### 1. Show exactly eight pooled Achievement entries

Change the Profile Achievement scroll configuration so:

```text
visibleRows = 8
```

The row height and spacing must be reduced to fit eight entries inside the existing Profile Achievement content area without expanding the Profile window.

Do not simply set `ENTRY_ROWS = 8` while retaining 78px rows and causing clipping/overflow. Derive/use a compact row height appropriate for the existing available viewport.

The final scroll viewport must visibly contain eight card slots at normal Profile window size.

### 2. Remove criterion/progress presentation from the card

The visible Achievement card must no longer show:

- `UI.ProgressBar`;
- `Criterion: Complete` / `Criterion: Incomplete`;
- `Criteria: X / Y complete`;
- numeric `current / goal` presentation.

Prefer removing the unused progress/criterion controls from `AchievementEntry` rather than continuing to construct hidden controls and reserving layout space for them.

Correspondingly remove the card-only `buildCriterionPresentation(...)` path from `page_ProfileAchievements.lua` if it has no remaining consumer.

This does **not** alter Achievement criterion runtime semantics. Criteria remain available to the tooltip and Achievement runtime.

### 3. Reflow the compact card

Preserve:

- icon;
- Achievement name;
- description;
- completed/incomplete visual distinction;
- completion state/date if currently shown on the card;
- reward delivery status where applicable.

Use the reclaimed criterion/progress space to reduce the overall row height rather than adding new card metadata.

Long names/descriptions must remain clipped/wrapped within the smaller card and must not overlap the footer.

The icon size should be reduced with the card if necessary; do not let the icon force the old 78px row height.

### 4. Center reward status at the bottom

`Rewards: ...` must be presented as a footer centered horizontally at the bottom of the entry.

Required behavior:

```text
Rewards: Pending
Rewards: Received
Rewards: Delivery failed
...
```

should use a full-width or otherwise genuinely centered footer region rather than the current right-aligned half-row.

If the Achievement has no reward status text, the footer should remain clean and should not reserve visibly awkward blank text.

Do not change reward delivery/retry semantics; this is presentation only.

### 5. Preserve sorting/filtering/recycling behavior

Do not regress the completed-first ordering implemented by #77:

```text
completed first
-> completedAt descending
-> source-order tie break
-> incomplete in authored order
```

Preserve category/subcategory filtering from #76 and pooled-row reset behavior added by #78 rev 1.

## Primary files

- `client/character/profile/page_ProfileAchievements.lua`
- `core/ui/prefabs/AchievementEntry.lua`

No Dataset/Profile schema change is required.

## Acceptance criteria

- [ ] Profile Achievement scroll view displays 8 entry slots at once at the existing normal window size.
- [ ] Cards are materially shorter than the current 78px design.
- [ ] Achievement cards show icon, name and description.
- [ ] No criterion summary is shown on an Achievement card.
- [ ] No progress bar/current-goal display is shown on an Achievement card.
- [ ] The card no longer reserves a hidden progress region.
- [ ] Reward status is centered horizontally at the bottom of the card.
- [ ] Existing reward states remain correctly represented.
- [ ] Reward display remains read-only and does not trigger delivery/retry.
- [ ] Existing completion styling/date behavior remains readable in the compact layout.
- [ ] Long text does not overlap the footer or adjacent rows.
- [ ] Completed-first/recency sorting remains unchanged.
- [ ] Category/subcategory filtering remains unchanged.
- [ ] Scroll recycling cannot leak icon/text/completion/reward state between rows.
- [ ] The Profile window itself is not enlarged to achieve eight rows.

## Validation matrix

```text
open All with >= 8 Achievements
-> exactly 8 card slots visible before scrolling

single progressive Achievement
-> no progress bar
-> no current/goal text on card

binary criterion Achievement
-> no Criterion: Complete/Incomplete line on card

multi-criterion Achievement
-> no criteria summary on card

reward pending
-> `Rewards: Pending` centered at bottom

reward failed
-> `Rewards: Delivery failed` centered at bottom

completed Achievement
-> compact completion treatment remains readable

long name + description
-> contained within compact card
-> does not overlap reward footer

scroll/rebind completed/reward-failed row into ordinary incomplete row
-> no stale completion/reward styling or text
```

## Constraints

- Do not change Achievement completion/criterion semantics.
- Do not change reward delivery logic.
- Do not expand the Profile window.
- Do not reintroduce generic `ScrollListEntry` rows; keep the dedicated Achievement prefab.
- Do not remove the Achievement tooltip's criterion data as part of this task; tooltip simplification is tracked separately.
- Preserve #64 revision-driven Profile refresh behavior.

## Coding-agent instructions

Use current `FrontierDev/rpe2` as authoritative. Inspect the actual available Achievement viewport height before choosing the compact row height; the product requirement is eight visible entries, not an arbitrary fixed pixel target. Remove card-only progress layout/control work instead of merely hiding it. Report final `visibleRows`, row height/spacing, compact card structure, files changed, and validation results.