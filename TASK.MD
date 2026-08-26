## Rev 1 validation: FAIL — tooltip hitch fixed, uncached snapshot blocker remains

Validated commit `66cc7596dfbcbed3d92e0becc50e79137734670f` (`Issue #63 rev 1`) against #63 and the previous in-game diagnostics. Ignoring `TASK.MD` as requested.

### What rev 1 fixes

The dominant page-render cost is addressed correctly:

- `InventoryGridPage:Refresh()` no longer eagerly constructs every populated slot's full item tooltip. It stores `slot.resolvedItem` and binds a lazy tooltip provider, so tooltip construction occurs only for the hovered slot.
- `ItemTooltip:Build()` now has direct timing instrumentation and logs a hard failure above 16 ms.
- Tooltip work is revision/cache keyed, including configuration and relevant runtime/profile/event revisions, item/stack/modification identity, with a separate static cache for non-dynamic tooltips.
- Dataset slot/stat lookup used by tooltip construction is indexed per ConfigurationRevision rather than repeatedly linearly scanned.
- Repeated unchanged tooltip builds can hit the cache.

This is consistent with the user's report that Inventory interaction is now **much, much faster** in-game.

### Remaining blocker: uncached display snapshot was not fixed

The previous validation identified a second independent cost: an uncached `Inventory.GetDisplaySnapshot()` took **81.70 ms for ~30 stacks**. Rev 1 does not modify `client/character/inventory/Inventory.lua`, so that path is unchanged.

Current code still does:

```lua
local function findDatasetItem(dataset, itemId)
    local items = dataset and dataset.items or nil
    ...
    for index = 1, #items do
        local item = items[index]
        if type(item) == "table" and tostring(item.id or "") == itemId then
            return item, index
        end
    end
end

local function resolveCanonicalItemDefinition(itemRecord)
    local dataset = Database.GetDatasetByID(itemRecord.dataset)
    local item = findDatasetItem(dataset, itemRecord.id)
    return dataset, item
end
```

`buildDisplaySnapshot()` invokes definition resolution for each Inventory record, so an uncached snapshot still performs repeated linear scans through each referenced dataset's item list. Removing eager tooltips makes the overall UI dramatically faster, but it does not satisfy #63's hard requirement that first/stale refresh work avoid an individual RPE frame >16 ms.

### Required fix for rev 2

Add a configuration-revision-aware item-definition index for the display-snapshot resolver, e.g.:

```text
datasetId -> {
  revision = ConfigurationRevision,
  dataset = dataset,
  itemById = { [itemId] = item }
}
```

Then `resolveCanonicalItemDefinition()` should use O(1) `itemById[itemRecord.id]` lookup rather than `findDatasetItem()` for every Inventory stack.

Requirements:

- invalidate/rebuild on `ConfigurationRevision` change;
- preserve missing-item/missing-dataset behavior;
- preserve activated/inactive dataset presentation semantics;
- do not change #62 Inventory storage/stacking semantics;
- cached `GetDisplaySnapshot()` behavior must remain effectively immediate.

### Re-validation

After that fix, repeat with `/rpe debug timings on`:

1. Force a stale/uncached Inventory snapshot and open Inventory with the same ~30-stack test set.
2. `Inventory.GetDisplaySnapshot` must no longer breach the 16 ms hard frame threshold.
3. Confirm first hover and repeated hover of representative simple/complex items do not log `HARD FAILURE ItemTooltip:Build` and feel immediate.
4. Confirm unchanged reopen remains on the existing fast path.

#63 remains open pending this final snapshot fix.