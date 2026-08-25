## Goal
Address four remaining UI/presentation issues found after runtime validation of the Guild Requisitions feature:

1. the Guild Ranks / GuildSetting inspector still does not visually match the established Spell/Item inspector conventions;
2. `ShopEntry` hover currently shows a simplified requisition tooltip instead of the actual RPE item tooltip;
3. `ShopEntry` costs show currency names instead of currency icons;
4. the Requisitions page needs explicit `Guild Shop` / `Requisitions` panel headers and slightly darker panel backgrounds, matching the visual treatment used by the Profile stats sheet.

This issue is UI/editor polish only. Preserve the existing requisition, Daily Reward, Guild Rank, reset, transaction, pagination, and persistence semantics.

## Important superseding design change
Previous Guild Requisitions tasks deliberately removed section headings from the page. This issue **supersedes that requirement only for the two main content panels**.

The final page should now include:

```text
Guild Shop                       Requisitions
[shop entries...]                [limited entries...]
```

Do not reintroduce instructional text, status paragraphs, empty-state prose, selection text, or a separate purchase button.

## Primary files

- `client/ui/editor/inspectors/page_InspectorGuildSetting.lua`
- `client/character/guild/page_GuildRequisitions.lua`
- `core/ui/prefabs/ShopEntry.lua` only if a reusable presentation API is required

Inspect/reuse established patterns from:

- `client/ui/editor/inspectors/page_InspectorSpell.lua`
- `client/ui/editor/inspectors/page_InspectorItem.lua`
- `client/ui/editor/inspectors/item/page_InspectorItemShared.lua`
- `client/ui/tooltips/tooltip_Item.lua`
- `client/character/profile/page_ProfileEquipmentStats.lua`
- existing Profile currency resolution APIs
- existing `UI.Panel`, layout-group, text, tooltip, and colour-token implementations

Do not create parallel inspector, tooltip, currency, or panel-style systems if the existing ones can be reused.

---

## 1. Make the Guild Ranks inspector visually consistent with Spell/Item inspectors

### Current problem
Issue #44 replaced raw requisition/reward references with dropdown selectors, but the overall GuildSetting/Guild Rank inspector still looks and behaves like a bespoke inspector rather than the standard Data Editor inspector family.

The Spell and Item inspectors establish the expected visual language: consistent selector bar, page spacing, field grouping, labels, control heights/widths, section/panel treatment, list/action rows, and page navigation.

### Required behavior
Refactor the GuildSetting inspector presentation so it follows the same conventions as the Spell/Item inspectors.

At minimum:

- use the same inspector-page shell/selector-bar proportions and spacing;
- use the same side padding and vertical spacing conventions;
- use the same label/control sizing conventions;
- use the same field-group / section-panel visual treatment where comparable;
- align Add/Delete/list controls with the same patterns used by existing inspectors;
- keep dataset/item/currency selector behavior from #44, but present those selectors consistently with other reference selectors;
- avoid one-off hard-coded visual rules where an existing shared inspector helper/component already exists;
- preserve the existing `General`, `Requisitions`, `Daily Rewards`, and `Progression` page split unless a small presentational reorganization is necessary for consistency.

This is **not** a request to change the GuildSetting schema or underlying editor behavior.

### Preserve

- current requisition IDs, quantities, character limits and costs;
- current Daily Reward type/ref/amount semantics;
- current progression configuration;
- #44 dataset/item/currency selector behavior and legacy-reference handling;
- existing pending dataset-change/coalescing behavior.

---

## 2. ShopEntry tooltip must use the actual Item tooltip

### Current problem
`RequisitionsPage:BindShopEntry(...)` currently supplies a simplified custom tooltip containing essentially the item name and cost.

That is not sufficient. A requisition/shop entry represents a real RPE item and should expose the same full item tooltip used elsewhere in the client.

### Required behavior
For a resolved requisition item, hovering either a Guild Shop entry or a limited Requisition entry must show the canonical RPE item tooltip produced by the existing item tooltip builder in:

```text
client/ui/tooltips/tooltip_Item.lua
```

Follow the same integration pattern used for equipped items in `page_ProfileEquipmentStats.lua` or another canonical caller.

The tooltip should therefore include whatever the Item tooltip builder normally provides for that item, such as applicable quality/category/item-level/stats/effects/description/etc., instead of replacing it with requisition-specific summary text.

### Resolution/context
When resolving the requisition `itemRef`, retain enough context to call the Item tooltip builder correctly:

- resolved item;
- dataset / dataset ID where available;
- dataset display name where applicable;
- item ID/ref;
- any other normal builder context that is available without inventing state.

If the item cannot be resolved, retain a safe fallback tooltip identifying the missing item/reference rather than erroring.

### Constraints

- tooltip hover must not purchase the item;
- tooltip generation must not mutate Profile state;
- exhausted/unaffordable entries must remain hoverable so the item tooltip still works;
- both left Guild Shop entries and right limited Requisition entries must use the same behavior.

---

## 3. ShopEntry costs must use currency icons instead of currency names

### Current problem
The current compact cost formatter produces text such as:

```text
25 Marks of Valor
```

This consumes too much horizontal space and does not match the intended compact visual design.

### Required behavior
Render each cost using the configured RPE currency icon and amount, not the currency name.

Conceptually:

```text
[currency icon] 25
```

For multiple currencies:

```text
[icon A] 25   [icon B] 3
```

Use the existing Profile currency resolver/definition as the source of the currency icon. Do not create a second currency registry.

### Fallbacks

- resolved currency with icon -> use its icon;
- resolved currency with missing/empty icon -> use the standard question-mark fallback icon;
- unresolved currency -> safe question-mark fallback plus amount;
- do not fall back to displaying the full currency name in the normal ShopEntry cost line.

The cost remains a single compact line underneath the item name and must continue to fit/truncate safely within both shop columns and the narrow limited-requisition panel.

If WoW inline texture markup is used, use the existing UI-supported format and a size appropriate to the ShopEntry cost font.

---

## 4. Add panel headers and darker panel backgrounds

### Required page structure
The main content region should now visually distinguish its two sections:

```text
[Daily Reward]  Guild Rank: ...
                Daily Reset in ...

┌ Guild Shop ───────────────────┐  ┌ Requisitions ─────────────┐
│ two-column paginated grid     │  │ one-column scroll list    │
│                               │  │                           │
└───────────────────────────────┘  └───────────────────────────┘
```

The exact border treatment need not literally match the ASCII example; the important requirements are header labels and distinct darker panel surfaces.

### Headers
Add visible section headers:

- `Guild Shop`
- `Requisitions`

Requirements:

- headers are part of their respective panels, not floating globally over the page;
- use the established Profile/UI header typography rather than ad-hoc font styling;
- left aligned;
- compact enough that the existing 2x7 shop layout remains practical;
- do not add a `Daily Rewards` heading.

### Darker panel treatment
The left Guild Shop region and right Requisitions region should both be slightly darker than the surrounding Guild window/page background.

Use the visual treatment already established by the Profile stats sheet (`client/character/profile/page_ProfileEquipmentStats.lua`) as the reference. Inspect and reuse the relevant panel/background colour token/component/treatment instead of guessing a new unrelated colour.

The two panels should use the same background treatment so they read as a coordinated pair.

### Preserve layout behavior

- left panel remains approximately 70% width;
- right panel remains approximately 30% width;
- Guild Shop remains exactly two columns;
- Guild Shop remains fixed-pool + manual pagination, not scrolling;
- limited Requisitions remain one-column `UI.ScrollLayout`;
- pagination controls remain associated with the Guild Shop panel;
- headers/backgrounds must not overlap entries, scrollbar, or pagination controls.

---

## Acceptance criteria

### GuildSetting inspector
- [ ] Guild Rank/GuildSetting inspector visually follows the same shell, spacing, sizing and section conventions as Spell/Item inspectors.
- [ ] Existing #44 dataset/item/currency dropdown behavior remains intact.
- [ ] No raw requisition/reward reference editing is reintroduced.
- [ ] No GuildSetting schema/business-logic change is introduced.

### Item tooltip
- [ ] Hovering a Guild Shop `ShopEntry` shows the canonical RPE item tooltip.
- [ ] Hovering a limited Requisition `ShopEntry` shows the same canonical RPE item tooltip.
- [ ] Item tooltip is built through the existing Item tooltip builder rather than a duplicate implementation.
- [ ] Missing/unresolved item references fail safely.
- [ ] Disabled/exhausted/unaffordable rows remain hoverable for tooltip purposes.

### Currency display
- [ ] Cost line displays currency icon + amount rather than currency name.
- [ ] Multiple cost currencies render as multiple compact icon/amount pairs.
- [ ] Missing currency icons use the standard fallback icon.
- [ ] Unresolved currencies fail safely.
- [ ] Cost text remains one line and does not bleed into adjacent entries/panels.

### Requisitions page panels
- [ ] Left panel has a visible `Guild Shop` header.
- [ ] Right panel has a visible `Requisitions` header.
- [ ] Both main panels use a slightly darker surface matching/reusing the Profile stats-sheet treatment.
- [ ] Headers are left aligned and visually consistent with existing Profile/UI headers.
- [ ] No extra help/status/empty-state prose is added.
- [ ] Existing 70/30 split, 2-column shop, pagination, and limited scroll behavior remain intact.

## Validation matrix

```text
GuildSetting inspector
-> compare side-by-side with Spell inspector
-> compare side-by-side with Item inspector
-> selector bar / page padding / fields / lists / actions read as same UI family

Guild Shop item hover
-> canonical Item tooltip appears

Limited Requisition item hover
-> same canonical Item tooltip appears

unresolved item
-> safe fallback, no Lua error

single currency cost
-> icon + amount; no currency name

multiple currency costs
-> each currency shown as compact icon + amount

missing/unresolved currency icon
-> question-mark fallback + amount

0 / 1 / 14 / 15 shop entries
-> panel header/background does not disturb pagination/grid behavior

limited list requiring scrollbar
-> header/background does not overlap scrollbar or rows

exhausted limited entry
-> disabled/subdued but item tooltip still works
```

## Coding-agent instructions
Treat current `FrontierDev/rpe2` as authoritative. Inspect the Spell and Item inspectors before changing `page_InspectorGuildSetting.lua`, and reuse their established visual/layout conventions rather than merely tweaking individual margins. For ShopEntry tooltips, use the existing `Addon.Client.UI.Tooltips.Item` builder and follow an existing canonical caller. For costs, resolve icons from the existing Profile currency definition. For the two panel surfaces, inspect the Profile stats-sheet implementation and reuse its established background/header treatment. Keep all gameplay/business logic unchanged and report exact files changed plus validation performed.