## Goal
Fix three UI problems found during runtime validation of the completed Guild Requisitions feature:

1. Guild Rank editor requisition/daily-reward references are currently entered as raw text references instead of using the existing dataset/entry selector patterns used elsewhere in the Data Editor.
2. The Daily Reward image button does not display its tooltip at runtime.
3. The Guild Rank and Daily Reset text are horizontally centered instead of left-aligned immediately beside the Daily Reward button.

These are UI/editor integration fixes only. Do not redesign requisition, Daily Reward, Guild Rank, reset, or transaction semantics.

## Observed runtime state
The final Requisitions page renders the Daily Reward image in the upper-left, but the rank/reset block is centered across the remaining header width rather than aligned next to the image. Hovering the Daily Reward image produces no tooltip.

The Guild Rank editor currently asks the author to type raw references for:

- requisition item references;
- Daily Reward item references;
- Daily Reward currency references.

This is inconsistent with the rest of the Data Editor and is error-prone.

## Primary files

- `client/ui/editor/inspectors/page_InspectorGuildSetting.lua`
- `client/character/guild/page_GuildRequisitions.lua`

Inspect for reusable patterns/components in:

- `client/ui/editor/inspectors/page_InspectorRecipe.lua`
- item/currency inspector helpers already exposed by the Data Editor
- `core/ui/Tooltip.lua`
- `core/ui/abstract/BaseElement.lua`
- `core/ui/abstract/ButtonBase.lua`
- `core/ui/elements/ImageButton.lua`
- layout group implementations as needed

## 1. Replace raw Guild Rank references with editor selectors

### Current problem
The Guild Rank inspector requires manually typed dataset-qualified references for requisition items and Daily Reward item/currency rewards.

Authors should not have to know or type values such as:

```text
my_dataset:item_id
my_dataset:currency_id
```

### Required behavior
Use the same general selector approach already used by the Recipes editor for referenced objects.

For **requisition items**:

- expose dataset selection and item selection via dropdowns or the closest existing reusable editor selector;
- populate the item selector from the selected dataset's `items` collection;
- store the same existing dataset-qualified `itemRef` value in the GuildSetting definition;
- preserve existing references when refreshing the inspector;
- gracefully represent a missing/unresolved legacy reference without silently replacing it.

For **Daily Reward `type = item`**:

- expose dataset + item selection using the same item-selector pattern;
- persist the same existing `reward.ref` schema value;
- only show/enable item selection while the reward type is `item`.

For **Daily Reward `type = currency`**:

- expose dataset + currency selection using the equivalent dataset/entry dropdown pattern;
- populate from the selected dataset's `currencies` collection;
- persist the same existing dataset-qualified `reward.ref` schema value;
- only show/enable currency selection while the reward type is `currency`.

Do not introduce a new reference format or schema. This is an authoring UI change only.

### Reuse existing editor patterns
`page_InspectorRecipe.lua` already contains dataset/entry selector behavior such as:

```lua
BuildRecipeInspectorDatasetItems(...)
BuildRecipeInspectorDatasetItemItems(...)
```

and uses dropdowns rather than requiring authors to type references. Follow/reuse that pattern where practical instead of creating a second reference-picker system.

If generic item/currency dataset selector helpers already exist in the Data Editor, prefer them over duplicating Recipe-specific code.

## 2. Fix Daily Reward button tooltip

### Current problem
`RequisitionsPage` assigns a tooltip to the Daily Reward `UI.ImageButton`, but no tooltip appears on hover at runtime.

The current page sets:

```lua
self.DailyRewardButton:SetTooltip(self.DailyRewardTooltip)
```

where `self.DailyRewardTooltip` is a function returning the current tooltip specification.

Inspect the actual `BaseElement`/tooltip contract and determine why this does not render. Fix the integration at the narrowest appropriate point.

### Required tooltip behavior
Hovering the Daily Reward button must display the existing configured Daily Reward tooltip, including:

- `Daily Rewards` title;
- Item reward names/icons/amounts;
- Currency reward names/icons/amounts;
- safe fallback for unresolved definitions;
- tooltip still available after the reward has been claimed.

Do not make tooltip hover trigger reward claiming, Profile writes, or any gameplay mutation.

Do not remove the existing post-claim hoverability requirement merely to make tooltip handling simpler.

If the root issue is that `BaseElement:SetTooltip`/`ShowTooltip` does not support a function-valued tooltip spec, either:

- update the page to provide a supported dynamic tooltip mechanism; or
- add narrow function-spec support to the shared tooltip plumbing if that is already consistent with other callers.

Avoid broad tooltip-system redesign.

## 3. Left-align Guild Rank / Daily Reset beside the reward button

### Current problem
The current header visually appears approximately as:

```text
[Reward]                 Guild Rank: Marshal
                         Daily Reset in 08:35:35
```

The text block is centered across the remaining width.

### Required layout
It should render as:

```text
[Reward]  Guild Rank: Marshal
          Daily Reset in 08:35:35
```

Specifically:

- Daily Reward button remains upper-left;
- Guild Rank text begins immediately to the right of the button with the existing header spacing;
- Daily Reset text is directly below Guild Rank and shares the same left edge;
- both text elements use left horizontal justification;
- the rank/reset block should not be centered in the remaining header area;
- keep the existing overall header height and button size unless a concrete layout constraint requires a small adjustment.

Prefer fixing the existing `HorizontalLayoutGroup` + `VerticalLayoutGroup` options/child text justification rather than manual frame anchoring.

## Constraints

Do not change:

- `characterLimit` semantics;
- requisition partitioning or pagination;
- requisition transaction logic;
- Daily Reward manual-claim semantics;
- Daily Reward reset-cycle semantics;
- Profile persistence/schema;
- Guild window dimensions or tab structure;
- Progression/Admin behavior;
- Issue #36 configuration-refresh coalescing.

Do not add new visible headings/help/status text to the Requisitions page.

## Acceptance criteria

- [ ] Requisition item authoring no longer requires manual reference entry.
- [ ] Requisition item selection uses dataset/entry dropdowns or the existing equivalent reusable selector.
- [ ] Daily Reward Item authoring no longer requires manual reference entry.
- [ ] Daily Reward Currency authoring no longer requires manual reference entry.
- [ ] Item/Currency reward controls switch appropriately with `reward.type`.
- [ ] Existing `itemRef` / `reward.ref` persisted formats remain unchanged.
- [ ] Existing valid references round-trip through editor refresh without being lost.
- [ ] Missing legacy references remain representable and are not silently overwritten.
- [ ] Hovering the Daily Reward button displays the configured tooltip.
- [ ] Tooltip remains available after claim.
- [ ] Tooltip hover performs no gameplay mutation.
- [ ] Guild Rank text is left-aligned immediately to the right of the Daily Reward button.
- [ ] Daily Reset text is left-aligned directly below Guild Rank.
- [ ] Header remains stable through refresh, claim, tab switching, and window show/hide.
- [ ] No unrelated gameplay/business logic changes are introduced.

## Validation matrix

Editor:

```text
requisition -> choose dataset -> choose item -> saved ref is dataset:item
reopen inspector -> same item selected

Daily Reward item -> choose type Item -> dataset/item controls active
reopen inspector -> same item selected

Daily Reward currency -> choose type Currency -> dataset/currency controls active
reopen inspector -> same currency selected

change type Item <-> Currency
-> irrelevant selector is hidden/disabled
-> selected ref updates only through the active selector

legacy/missing ref
-> inspector does not crash
-> unresolved value is not silently replaced
```

Runtime header:

```text
open Guild -> rank/reset left aligned beside image
resize/show/hide/tab switch -> alignment remains correct
```

Tooltip:

```text
available reward -> hover shows tooltip
claimed reward -> hover still shows tooltip
item + currency rewards -> names/icons/amounts shown
missing definition -> safe fallback
hover only -> no claim / no Profile mutation
```

## Coding-agent instructions
Treat current `FrontierDev/rpe2` as authoritative. Inspect the Recipes editor reference-picker implementation before changing the Guild Rank inspector. Reuse existing Data Editor selector helpers wherever practical. Inspect the shared tooltip contract before changing `page_GuildRequisitions.lua`; fix the narrow integration defect rather than adding a parallel tooltip implementation. Keep the header layout group-based and make only the alignment changes required above. Report exact files changed and validation performed.