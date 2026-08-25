## Goal
Rework the Guild **Admin** page so the roster and administration controls use the current RPE UI system cleanly and consistently.

Runtime issues visible in the current Admin page:

1. the guild roster is a `ScrollLayout`/`ScrollListEntry` list rather than a proper table;
2. the lower administration controls are laid out with many independent absolute `SetPoint` offsets and are visually cramped/misaligned;
3. Guild Rank / Achievement / Skill / Item reference dropdowns are flat lists rather than hierarchical dataset-based selectors;
4. Online/Offline state is not visually distinct enough;
5. members are not presented in Guild Rank order.

This is primarily a UI/layout refactor. Preserve all existing Guild Admin authority checks, member querying, mutation semantics, comms, pending-action gating, selected-member state, achievement/skill/item/rank operations, and any existing progression administration behavior.

## Current source observations

Primary page:

- `client/character/guild/page_GuildAdmin.lua`

The current roster is implemented using:

```lua
UI.ScrollLayout
rowElementClass = UI.ScrollListEntry
```

and manually combines fields such as Guild Rank + zone into row text.

The repository already has a proper table implementation at:

- `core/ui/prefabs/Table.lua`
- `core/ui/prefabs/TableRow.lua`

`UI.Table` already supports named columns, headers, scrolling, sort state, `sortValue`, filtering, and reusable `TableRow` cells. `TableRow` already supports a row mouse-up handler, so preserve selectable roster rows rather than making the new table display-only.

The dropdown system already supports nested `children` through `UI.Dropdown` / `UI.ContextMenu`. The Recipe inspector demonstrates the desired multi-level pattern in:

- `client/ui/editor/inspectors/page_InspectorRecipe.lua`

For example, Recipe output selectors construct non-selectable parent groups using:

```lua
{
    label = "...",
    value = "...group...",
    enabled = true,
    keepShownOnClick = true,
    notCheckable = true,
    children = { ... },
}
```

Use that established mechanism rather than implementing a second dropdown/menu system.

## 1. Replace the guild roster with `UI.Table`

Replace `RPEGuildRosterList` with a `UI.Table`.

Recommended columns, using the data already available on roster members:

```text
Character | Guild Rank | Level | Class | Zone | Status
```

Requirements:

- use `UI.Table`, not a custom collection of FontStrings and not another `ScrollLayout` pretending to be a table;
- retain a scrollable body and compact row height appropriate to the Guild window;
- retain member selection by clicking a row;
- selected-member highlighting must remain visible;
- selection must continue to drive the existing Admin query/mutation state exactly as before;
- do not lose currently available roster data (`name`, `rankName`, `rankIndex`, `level`, `className`, `zone`, `online`);
- table headers should be visible and aligned with their columns;
- remove the old concatenated `rankName .. " - " .. zone` presentation once those values have dedicated columns.

If `UI.Table` needs a **small reusable hook** to expose its existing `TableRow:SetRowMouseUpHandler(...)` capability through table options/row rendering, add that narrowly in `Table.lua`; do not special-case Guild Admin inside the core prefab.

## 2. Default roster ordering: Guild Rank

The roster must default to WoW Guild Rank order using the numeric roster `rankIndex`, not an alphabetical comparison of the displayed rank name.

Expected order:

```text
rankIndex 0
rankIndex 1
rankIndex 2
...
```

where lower `rankIndex` means the higher WoW Guild Rank.

For members with the same rank, use character name alphabetically as the deterministic tie-breaker.

Do **not** group online users ahead of higher-ranked offline users: Guild Rank is the primary ordering requested here.

If interactive table sorting is retained, opening/refreshing the Admin page must still restore or default to Guild Rank ascending unless the existing table conventions clearly preserve an intentional user-selected sort.

## 3. Online status colors

The `Status` table cell must show:

- **Online** in green;
- **Offline** in grey/muted text.

Use existing RPE UI color tokens where an appropriate success/positive and muted color already exists. Avoid hard-coding a new visual palette unnecessarily.

The color must be applied to the status cell/text only; do not tint the entire roster row green/grey.

If dynamic per-row cell color is not currently supported by `TableRow`, prefer a small reusable table-cell color callback/API over page code reaching directly into private FontStrings. Keep any core UI change generic.

## 4. Clean up the lower Admin-control layout

The lower Admin panel currently relies on many independent absolute offsets such as:

```lua
control:GetFrame():SetPoint("TOPLEFT", ..., x, y)
```

Rebuild this area primarily with `VerticalLayoutGroup` / `HorizontalLayoutGroup` and existing panel helpers so controls align predictably.

Suggested hierarchy:

```text
Vertical Admin Controls
├─ Selected-member summary
├─ Horizontal Rank Controls
│  ├─ Guild Rank dropdown
│  ├─ Set Rank
│  └─ Clear Rank
├─ Section-specific action area
│  ├─ Achievements controls OR
│  ├─ Skills controls OR
│  ├─ Items controls OR
│  └─ existing progression controls, if present
└─ Horizontal section selector
```

Requirements:

- consistent field heights;
- consistent gaps/padding;
- dropdowns should use available horizontal width instead of arbitrary mismatched widths;
- labels/state text and action buttons should align vertically with their related selector;
- avoid overlapping controls at the current Guild window size;
- preserve the current Admin section switching and button enable/disable logic;
- preserve selected-member summary/status messaging, but fit it into the cleaned-up layout rather than allowing it to collide with controls.

Do not redesign the whole Guild window or the Requisitions/Progression tabs in this task.

## 5. Convert reference dropdowns to multi-level selectors

The current helper `buildReferenceItems(collectionKey)` flattens entries from all activated datasets into labels like:

```text
Entry Name (Dataset Name)
```

Replace the flat reference menus with hierarchical dropdown items following the Recipe inspector pattern.

At minimum convert these Admin selectors:

- Guild Rank;
- Achievement;
- Skill;
- Item.

Expected structure for dataset-backed references:

```text
Dataset A
  Achievement A
  Achievement B

Dataset B
  Achievement C
```

and analogously for Skills and Items.

For Guild Rank, group the **eligible** `GuildSetting` matches by dataset:

```text
Dataset A
  Marshal
  Crusader

Dataset B
  ...
```

Requirements:

- parent dataset entries are non-selectable category nodes (`notCheckable = true`) with `children`;
- leaf values continue to be the exact existing dataset-qualified references expected by Guild Admin operations;
- do not change reference persistence or comms payload format;
- continue to restrict Guild Rank choices to `EligibleGuildRanks` for the selected member;
- Achievement / Skill / Item choices continue to come from the currently appropriate activated datasets used by runtime Guild Admin;
- preserve empty/unavailable states safely;
- leaf labels should be the human-readable entry names, falling back to IDs where required;
- dataset labels should use the human-readable dataset name where available;
- no duplicate reference leaf should be emitted.

If an existing selector on this page is not dataset-backed (for example a progression slot number or an entry derived only from the selected rank), do not force it into an artificial dataset hierarchy.

## 6. Preserve Admin behavior

This UI rework must not change the security/transaction layer.

Preserve:

- officer capability detection;
- requirement that remote admin targets are online where currently required;
- query/pending state behavior;
- rank assignment eligibility checks;
- Set Rank / Clear Rank behavior;
- Achievement grant behavior;
- Skill adjustment behavior;
- Item grant behavior;
- existing progression mutation behavior;
- current comms protocol and opcodes;
- refresh behavior after mutations;
- selected member identity handling / normalized names.

No schema changes should be required.

## Acceptance criteria

- [ ] Guild roster uses `UI.Table`.
- [ ] Table has clear columns instead of concatenated row text.
- [ ] Clicking a table row still selects the member and drives the existing Admin workflow.
- [ ] Members default-sort by numeric WoW Guild Rank (`rankIndex`, lowest first), then name.
- [ ] Online members show green `Online` status text.
- [ ] Offline members show grey/muted `Offline` status text.
- [ ] Lower Admin controls are rebuilt with layout groups and no longer look cramped/misaligned.
- [ ] Guild Rank selector is hierarchical by dataset and contains only eligible ranks.
- [ ] Achievement selector is hierarchical by dataset.
- [ ] Skill selector is hierarchical by dataset.
- [ ] Item selector is hierarchical by dataset.
- [ ] Parent dropdown nodes are categories only; leaf values retain existing dataset-qualified refs.
- [ ] No Guild Admin authority, comms, transaction, persistence, or progression behavior is changed.
- [ ] Requisitions and Progression Guild tabs are unaffected.

## Validation matrix

```text
roster with ranks 0, 1, 1, 3
-> order is rank 0, rank 1 members alphabetically, then rank 3

online member
-> Status cell says Online in green

offline member
-> Status cell says Offline in grey

click table row
-> selected-member summary changes to that member
-> online member query behavior still runs as before

Guild Rank dropdown
-> Dataset -> eligible rank leaf
-> ineligible ranks are absent

Achievement / Skill / Item dropdown
-> Dataset -> entry leaf
-> selecting leaf stores/uses the same existing reference value

switch Achievements / Skills / Items sections
-> only relevant controls are shown
-> alignment remains stable

Admin action pending / target offline / no officer access
-> same controls disabled and same security behavior as before

refresh roster
-> rank ordering and selected-member handling remain valid
```

## Coding-agent instructions
Use current `FrontierDev/rpe2` as authoritative. Before editing, inspect `client/character/guild/page_GuildAdmin.lua`, `core/ui/prefabs/Table.lua`, `core/ui/prefabs/TableRow.lua`, `core/ui/elements/Dropdown.lua`, `core/ui/elements/ContextMenu.lua`, and the hierarchical selector builders in `client/ui/editor/inspectors/page_InspectorRecipe.lua`. Reuse those systems rather than duplicating them. Keep any core Table/TableRow enhancements generic and minimal. Report exact files changed and runtime/static validation performed.