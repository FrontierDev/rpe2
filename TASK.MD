## Goal
Create the reusable `ShopEntry` UI prefab used by both the paginated Guild Shop and the limited Requisitions scroll panel.

Authoritative plan: `.docs/RPE2-Final-Guild-Requisitions-Page-Implementation-Plan.md`.

Depends on: #38

`ShopEntry` must visually follow `core/ui/prefabs/SpellbookEntry.lua`: icon on the left, compact text region on the right, hover treatment, disabled/desaturated state and responsive layout metrics. The text region differs by containing **item name on the first line and item cost directly underneath**.

## Primary files
- new `core/ui/prefabs/ShopEntry.lua`
- `RPEngine_Dev.toc`
- `core/ui/Constants.lua` only if a narrow prefab constants block is consistent with the current prefab pattern after inspection

## Visual contract
Required layout:

```text
┌──────┬────────────────────────┐
│ ICON │ Item Name              │
│      │ Item Cost              │
└──────┴────────────────────────┘
```

Retain the relevant `SpellbookEntry` behavior/style:

- Button-backed outer frame;
- left-side icon frame;
- cropped icon texture;
- thin icon border;
- hover highlight;
- enabled/disabled visual treatment;
- `SetBorderColor(...)`;
- responsive `SetLayoutMetrics(width, height)`;
- normal `BaseElement` tooltip support.

Do not copy unrelated Spellbook behavior such as action-bar binding or spell-specific fields.

## Internal layout
Use RPE layout abstractions where practical.

The icon remains the fixed left region. The text area to its right should contain a small `VerticalLayoutGroup` with:

1. one-line item-name text;
2. one-line cost text.

Avoid independently hand-anchoring two arbitrary text rows if the existing Vertical Layout Group can express the same structure.

The overall entry should remain compact and comparable in height to `SpellbookEntry` so a two-column grid can display multiple rows within the current Guild window.

## Public API
Provide at minimum:

```lua
ShopEntry:SetIcon(texturePath)
ShopEntry:SetItemName(itemName)
ShopEntry:SetCostText(costText)
ShopEntry:SetBorderColor(r, g, b, a)
ShopEntry:SetLayoutMetrics(width, height)
ShopEntry:SetEnabled(enabled)
```

`SetTooltip(...)` should work through inherited `BaseElement` behavior without introducing a second tooltip system.

Store the full item name separately from the rendered/truncated string.

## Item-name truncation
The item name must:

- remain on one line;
- never wrap;
- never bleed into the adjacent Guild Shop column;
- render `...` when the full text does not fit.

Example:

```text
Reinforced Arcanite Longs...
```

Implement a focused fitting helper inside `ShopEntry.lua`, conceptually:

```lua
local function fitTextWithEllipsis(fontString, fullText, maxWidth)
    -- full text if it fits
    -- otherwise longest fitting prefix .. "..."
end
```

Prefer binary search over candidate string length rather than removing one character repeatedly.

Recompute truncation whenever:

- `SetItemName()` changes the full name;
- `SetLayoutMetrics()` changes the available text width;
- any relevant font/layout metric is reapplied during creation.

The displayed text must never become the source of truth for tooltips or data binding; preserve the full name internally.

## Cost line
The cost appears directly underneath the name.

Requirements:

- single line;
- slightly smaller than the item-name text;
- secondary/muted text color;
- no visible `Cost:` prefix added by the prefab;
- does not overflow outside the entry.

It may use the same fitting helper if necessary. The explicit required truncation behavior is for the item name, but cost overflow must still remain visually contained.

The page will supply already-formatted cost text; `ShopEntry` should not resolve Currency definitions itself.

## Enabled/disabled state
Mirror `SpellbookEntry` semantics:

- disabled icon desaturates/dims;
- name and cost become subdued;
- outer frame visual alpha updates coherently;
- the prefab should remain safe for tooltip use where the caller deliberately keeps hover enabled.

Do not encode requisition eligibility rules inside the prefab.

## Load order
Add:

```text
core/ui/prefabs/ShopEntry.lua
```

to `RPEngine_Dev.toc` after `SpellbookEntry.lua` and before Guild UI pages that consume it.

Do not reorder unrelated files.

## Constraints
- Do not implement Guild Shop pagination here.
- Do not implement Requisition transaction calls here.
- Do not resolve Items/Currencies here.
- Do not create a Shop-specific tooltip framework.
- Do not modify `SpellbookEntry.lua` merely to share small implementation details unless a tiny genuinely reusable helper already belongs elsewhere.
- Do not add visible labels/help text.

## Acceptance criteria
- [ ] `UI.ShopEntry` loads before Guild UI consumers.
- [ ] The prefab matches the Spellbook visual language.
- [ ] Item icon is on the left.
- [ ] Item name is above cost in the right-hand text region.
- [ ] Item name is strictly one line.
- [ ] Overlong item names are truncated with `...` rather than wrapped or clipped into another column.
- [ ] Truncation recalculates after width changes.
- [ ] Full item name is preserved internally.
- [ ] Cost is directly below the name, smaller/subdued, and visually contained.
- [ ] `SetIcon`, `SetItemName`, `SetCostText`, `SetBorderColor`, `SetLayoutMetrics` and `SetEnabled` work after creation.
- [ ] Existing BaseElement tooltip support works on ShopEntry.
- [ ] Disabled-state visuals remain coherent.

## Coding-agent instructions
Read `.docs/RPE2-Final-Guild-Requisitions-Page-Implementation-Plan.md`, then inspect `core/ui/prefabs/SpellbookEntry.lua`, `TrainerEntry.lua`, `VerticalLayoutGroup.lua`, `Text.lua`, `BaseElement.lua`, and the prefab load-order section of `RPEngine_Dev.toc` before editing. Implement Task 2 only. Clone the established visual behavior rather than inventing a new row style, and validate truncation at multiple widths. Review every acceptance criterion and report changed files, validation performed, and any deviation.