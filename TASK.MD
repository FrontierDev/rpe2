## Goal
Advance `item_gain` criteria from actual successful canonical RPE item additions.

Depends on: #23, #24

## Primary files
- `client/client_Achievements.lua`
- `client/character/inventory/Inventory.lua` only if a narrow post-add notification/hook is required
- `core/internal/Runtime.lua` only if listener registration must be deferred
- `RPEngine_Dev.toc` only if load order needs correction

## Canonical authority
The canonical gain source is successful:

```lua
Client.Inventory.AddItem(...)
```

Inspect the current Inventory implementation and existing change-notification path before adding anything. If the existing notification exposes enough information, consume it. Otherwise add the smallest post-success listener/callback at the canonical `AddItem` boundary.

Do not count:

```text
Inventory load
SetItems state replacement
normalization
RemoveItem/Delete
UI refresh
```

## Trigger context
Provide enough information for matching/progress, conceptually:

```lua
{
    itemRef = "dataset:item",
    datasetId = "dataset",
    itemId = "item",
    amount = actualAddedQuantity,
    source = "inventory-add",
}
```

`amount` must be the quantity actually added successfully, not merely requested.

## Intentional gain sources
Because they use canonical Inventory awards, these should count naturally:
- Guild Requisition;
- Daily Reward;
- Guild Admin Give Item;
- future Achievement Item rewards.

Do not special-case those callers individually if one canonical Inventory gain hook can cover them.

## Filter semantics
If `filters.itemRef` is configured, require exact qualified-reference match.

## Load order
Inspect `RPEngine_Dev.toc`: `client_Achievements.lua` and Inventory may not be available in the order a direct file-load registration would assume. Use an existing deferred Runtime/addon-ready pattern where necessary rather than creating a brittle nil-order dependency.

## Constraints
- Do not change Inventory persistence/stacking/BOP semantics.
- Do not trigger from Inventory initialization/loading.
- Do not add a second Inventory event system if the existing notification path is suitable.
- Do not implement Skill/Event/Combat triggers in this task.

## Acceptance criteria
- [ ] Successful `AddItem()` advances matching `item_gain` criteria.
- [ ] Quantity >1 advances by actual added quantity exactly once.
- [ ] `itemRef` filter requires exact qualified-reference match.
- [ ] Nonmatching Items do not progress the criterion.
- [ ] Inventory load/normalization/`SetItems()` does not count as gain.
- [ ] Item removal does not count.
- [ ] Existing stacking/max-stack/BOP behavior is unchanged.
- [ ] Requisition/Daily Reward/Guild Admin Item grants reach the same canonical gain path.

## Coding-agent instructions
Read the PDD and completed issues #23–#24, then inspect `Inventory.AddItem`, Inventory change notification, TOC load order, and the current Achievement trigger dispatch API before editing. Implement Task 3 only. Prefer one canonical post-success Item gain boundary over caller-specific hooks. Use actual applied quantity and verify that load/removal paths cannot emit progress. Review every acceptance criterion and report changed files, validation performed, and deviations.