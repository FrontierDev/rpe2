## Goal

Rework Profile -> Achievements so the main Achievement list reads like an Achievement interface rather than a generic text list, while preserving RPE's existing data/runtime semantics.

Completed Achievements must be shown **before incomplete Achievements**, with completed entries ordered by `completedAt` **most recent first**.

This task should use World of Warcraft's Achievement UI as the visual/interaction reference for information hierarchy, but adapt it to RPE's actual data model rather than copying Blizzard templates or inventing unsupported concepts such as Achievement Points.

Depends on: #76

## Current-code investigation / root cause

Primary file:

- `client/character/profile/page_ProfileAchievements.lua`

### 1. The main list is a generic `ScrollListEntry`

The page currently uses `UI.ScrollLayout` with:

```lua
rowElementClass = UI.ScrollListEntry
```

for both navigation and the main Achievement rows.

The Achievement content rows are fixed at approximately:

```text
ENTRY_HEIGHT = 64
ENTRY_ROWS   = 4
```

and squeeze Achievement-specific content into the generic row's icon/category/status/text slots.

This is the principal visual limitation: the generic list row has no Achievement-specific hierarchy for name, description, progress, completion state/date and rewards.

### 2. Criterion presentation is flattened into text

The current `buildCriterionProgress()` path turns criterion progress into a concatenated inline status string. This is compact but visually dense and does not resemble the way WoW presents Achievement progress.

### 3. There is no Achievement ordering step

`buildAchievementRows()` walks activated datasets and their Achievement arrays in source/definition order. The page does not sort Achievement rows by completion state or timestamp.

Therefore completed Achievements can appear anywhere in the list, and recently completed Achievements receive no presentation priority.

### 4. Completion data already exists

Profile Achievement state already exposes `completedAt`, and the page already formats a completion date. No runtime or Profile schema change is needed to implement the requested ordering.

## WoW Achievement UI reference

Reference sources inspected:

- Warcraft Wiki — Achievements: https://warcraft.wiki.gg/wiki/Achievements
- Current Blizzard Achievement UI source mirror: https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_AchievementUI/Mainline/Blizzard_AchievementUI.lua

Relevant characteristics of the native UI:

- a dedicated left category pane and dedicated main content pane;
- each Achievement is a purpose-built card/button rather than a generic list row;
- icon on the left;
- Achievement name is visually dominant;
- description sits directly beneath the name;
- completion date is visible for completed Achievements;
- progress bars are used where an Achievement has progressive numeric completion;
- individual criteria can be represented separately rather than concatenated into one technical status string;
- completed entries have a distinctly brighter/gold treatment while incomplete entries are visually subdued;
- the native implementation intentionally allows several text lines in a collapsed Achievement card (`ACHIEVEMENTUI_MAX_LINES_COLLAPSED = 3`);
- native pane widths are roughly 175 px for categories and 330 px for Achievement content, which is already close to RPE's current 168/340 split. The broad two-pane geometry therefore does **not** need a wholesale redesign.

WoW also displays Achievement Points/shields because those are part of Blizzard's Achievement model. RPE has no Achievement-point field and must not invent one for visual parity.

The requested completed-first/most-recent-first ordering is an explicit RPE requirement for this issue. Do not assume Blizzard's normal list ordering is authoritative for that part.

## Required solution

### 1. Add a dedicated `AchievementEntry` prefab

Create a reusable Achievement-specific row/card, for example:

```text
core/ui/prefabs/AchievementEntry.lua
```

and use it as the main Achievement `ScrollLayout` row class.

The prefab should follow the existing RPE prefab conventions (`SpellbookEntry`, `ShopEntry`, etc.) and expose data/presentation setters rather than letting `page_ProfileAchievements.lua` reach directly into private frame children.

Recommended collapsed layout:

```text
┌──────────────────────────────────────────────┐
│ [ICON]  Achievement Name                    │
│         Description text...                 │
│         [progress / criterion summary]      │
│                           Completed 28/08/26 │
└──────────────────────────────────────────────┘
```

For an incomplete Achievement:

```text
┌──────────────────────────────────────────────┐
│ [ICON]  Achievement Name                    │
│         Description text...                 │
│         [████████░░░░] 7 / 10               │
└──────────────────────────────────────────────┘
```

Exact pixel dimensions may follow the current Profile content width, but the row must provide enough vertical structure for the fields instead of forcing all metadata into one line.

### 2. Visual hierarchy

Each entry must support:

- Achievement icon on the left with normal RPE icon crop/border treatment;
- name as the strongest text element;
- description directly below the name, wrapping/truncating safely within the row;
- progress presentation below the description where applicable;
- completion date on completed entries;
- compact reward text/state where current Achievement reward UI requires it;
- distinct completed vs incomplete visual state.

Use existing RPE colour tokens/textures where possible.

Recommended state treatment inspired by WoW:

```text
completed   -> brighter/gold-accent border/header treatment, normal icon
incomplete  -> darker/subdued surface and/or desaturated icon/accent
```

Do not make incomplete entries unreadable. Do not tint the entire UI with hard-coded Blizzard colours if equivalent RPE tokens exist.

### 3. Improve progress presentation

Replace the current single concatenated criterion string in the visible card with structured presentation.

At minimum:

- a single progressive numeric criterion (`goal > 1`) should use `UI.ProgressBar` plus `current / goal`;
- a single binary criterion can use a compact complete/incomplete criterion line rather than a meaningless 0/1 bar if that reads better;
- multiple criteria should use a compact criterion summary that does not become an unbounded one-line string;
- detailed per-criterion information may remain available through the dedicated Achievement tooltip task; the list card does not have to expose every long criterion description at once.

Do not sum heterogeneous criterion goals into a misleading aggregate value merely to make a bar.

If a compact multi-criterion display is used, it should represent actual completed criterion count or a small bounded set of criterion lines, not a fabricated progress percentage.

### 4. Preserve current reward-state information without dominating the row

Issue #34 added Achievement reward delivery/status presentation. Do not lose that information.

Where an Achievement has rewards, the card may show a compact user-facing reward/status line such as the existing resolved summary. Detailed reward diagnostics/recovery data can remain in the Achievement tooltip or existing explicit retry UI where appropriate.

Do not cause reward delivery/retry merely by binding or showing a row.

### 5. Completed-first, recency sorting

Add an explicit deterministic sort for the visible Achievement rows.

Required comparator:

```text
A completed, B incomplete
-> A first

A incomplete, B completed
-> B first

A completed, B completed
-> larger completedAt first (most recent completion first)

A incomplete, B incomplete
-> preserve existing authored/source order
```

Because Lua `table.sort()` is not stable, capture a deterministic `sourceOrder`/`sourceIndex` while building the rows and use it as the tie-breaker:

```text
same completion timestamp -> sourceOrder ascending
both incomplete           -> sourceOrder ascending
```

Do not alphabetize incomplete Achievements as an accidental side effect of the new comparator unless separately requested.

The sorting rule applies consistently within:

```text
All
built-in category
subcategory
```

filters introduced by #76.

### 6. Keep filtering and sorting separate

Recommended flow:

```text
build read-only Achievement row/view-model data
-> filter by selected category/subcategory
-> sort the filtered rows by completion/recency/sourceOrder
-> bind AchievementEntry rows
```

Equivalent ordering is acceptable if it produces the same deterministic visible result.

Do not mutate the underlying dataset arrays to sort the UI.

### 7. Keep Profile lifecycle/recycling efficient

Preserve the revision-driven Profile UI work from #64:

- `Build()` constructs controls only;
- hidden Achievement page does no rendering work;
- `RefreshIfDirty()` consumes Achievement/Configuration revisions;
- use the existing `ScrollLayout` row recycling model;
- do not eagerly build expensive tooltip text for every row during refresh;
- do not create/destroy a complete frame tree for every scroll operation.

If a dedicated row prefab needs a small generic `ScrollLayout` hook, keep it reusable; `ScrollLayout` already accepts `rowElementClass`, so a core rewrite should not normally be needed.

## Primary files

- `client/character/profile/page_ProfileAchievements.lua`
- `core/ui/prefabs/AchievementEntry.lua` — new
- `RPEngine_Dev.toc` — load prefab before the Profile Achievement page

Potential supporting file only if a concrete reusable gap is found:

- `core/ui/elements/ScrollLayout.lua`

Do not modify Achievement runtime/state semantics in this issue.

## Acceptance criteria

- [ ] Main Achievement rows use a dedicated Achievement-specific prefab instead of generic `ScrollListEntry` presentation.
- [ ] Every row clearly presents icon, name and description.
- [ ] Completed/incomplete rows are visually distinguishable without sacrificing readability.
- [ ] Completed rows display completion date.
- [ ] Progressive single-criterion Achievements use a real progress bar/current-goal presentation where appropriate.
- [ ] Multiple criteria no longer collapse into an unbounded technical one-line string.
- [ ] Existing reward-state information remains accessible and ordinary row binding remains read-only.
- [ ] Completed Achievements appear before every incomplete Achievement.
- [ ] Completed Achievements are sorted by `completedAt` descending.
- [ ] Equal completion timestamps use deterministic source-order tie-breaking.
- [ ] Incomplete Achievements retain current authored/source order.
- [ ] Sorting behaves the same under All/category/subcategory filters from #76.
- [ ] No dataset array/Profile state is mutated to achieve UI sorting.
- [ ] The category/content pane geometry remains compatible with the current Profile window.
- [ ] No Achievement Points/score field is invented merely to mimic WoW's shield.
- [ ] Long names/descriptions/progress text remain contained within the card and do not overlap adjacent UI.
- [ ] Scroll row recycling does not leak completion styling, progress bars, dates or reward text between rebound rows.
- [ ] Opening/reopening the unchanged Profile Achievement tab retains the revision-driven fast path.

## Validation matrix

```text
completed timestamps: A=100, B=300, C=200; D incomplete
-> visible order B, C, A, D

A/B same completedAt; source order A before B
-> A before B deterministically

3 incomplete Achievements authored C, A, B
-> remain C, A, B

filter Combat
-> completed Combat first by most-recent date
-> incomplete Combat follow in authored order

filter Combat / Raids
-> same sorting rule inside subcategory

single criterion current 7 / goal 10
-> progress bar + 7 / 10

multi-criterion Achievement
-> bounded readable criterion summary
-> no long concatenated overflow

completed Achievement with reward
-> completion state/date and compact reward information visible
-> no reward mutation occurs from display

incomplete Achievement with no Profile state
-> safe 0/default progress and incomplete style

long name + long description
-> wraps/truncates within card
-> no overlap with completion/status region

scroll/recycle completed row into incomplete data
-> completed border/date/icon treatment fully resets

close/reopen unchanged Profile
-> no unnecessary full presentation rebuild
```

## Constraints

- Do not change Achievement criteria completion semantics.
- Do not change `completedAt` persistence or completion runtime behavior.
- Do not reorder or rewrite dataset definitions themselves.
- Do not invent Achievement Points.
- Do not import/copy Blizzard Achievement XML/templates as a parallel UI system; reproduce the useful hierarchy using RPE UI abstractions.
- Do not make tooltips eagerly during list refresh; a dedicated tooltip issue follows.
- Preserve reward retry/security behavior.
- Preserve #64 Profile revision/dirty lifecycle.

## Coding-agent instructions

Use current `FrontierDev/rpe2` as authoritative and implement after #76 so the final list consumes the explicit category/subcategory model. Before editing, inspect `page_ProfileAchievements.lua`, `ScrollLayout`, `ScrollListEntry`, `SpellbookEntry`, `ShopEntry`, `ProgressBar`, current reward-state display, and the current TOC order. Use the WoW Achievement UI sources above as a visual hierarchy reference, not as a code/template dependency. Report the final card structure, comparator/tie-break behavior, files changed, and runtime/static validation against the matrix.