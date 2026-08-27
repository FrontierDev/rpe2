## Static validation: FAIL — Traits tab omits runtime inputs it actually renders

Validated current `main` at `ec15319eac2196b9158abed029e8ba270490e120` (`Issue #64`) against the #64 body and runtime-performance plan. `TASK.MD` is intentionally ignored per user instruction.

A large portion of the implementation is correct: Profile pages use Build-only + `RefreshIfDirty`, Equipment/Stats has a revision-keyed presentation snapshot reusing the existing resolved stat/resource caches, mount/pet lists are scope-gated/cached, item/stat/trait/spell tooltip work is lazy, and `ProfileWindow:HandleRuntimeChange()` narrows Equipment/Skills/Achievements/action-bar invalidation.

### Blocking defect: Traits can display stale consumable/equipment rows

`page_ProfileTraits.lua` currently defines its revision tuple as only:

```lua
{
    configurationRevision,
    selectedCategoryKey,
    currentTraitPage,
}
```

It has **no Runtime revision inputs**.

However the data rendered by this page is runtime-dependent:

- `Client:BuildProfileTraitRows()` includes `Profile.ListAvailableConsumableTraits()` and `Profile.ListEquippedItemTraits()`.
- `Profile.ListAvailableConsumableTraits()` calls `Inventory.GetDisplayItems()` and therefore changes when `InventoryRevision` changes.
- `Profile.ListEquippedItemTraits()` reads equipped slots and therefore depends on equipment state.

At the window level, `ProfileWindow:HandleRuntimeChange()` currently recognizes only `equipmentChanged`, `skillsChanged`, `achievementsChanged`, and `spellbookChanged`. It never derives a `traitsChanged` condition and never marks the Traits page dirty for `changeSet.inventory` / `InventoryRevision`.

### Result

A concrete stale-state path exists:

```text
open/build Traits tab -> render consumable traits -> leave tab (or remain on it)
receive/remove an Inventory item with a consumableTrait
-> InventoryRevision changes
-> ProfileWindow runtime listener does nothing for Traits
-> TraitsPage revision tuple is unchanged
-> next RefreshIfDirty fast-paths
-> consumable trait list remains stale
```

The same page also directly renders equipped-item traits, so its signature should include the narrow equipment dependency rather than relying indirectly on broad `ConfigurationRevision` behavior.

This fails #64 requirements that each Profile page track the revisions that actually affect its output, that committed changes dirty only the relevant tabs, and that Profile values/interactions remain correct.

### Required fix

1. Add Runtime revision access to `page_ProfileTraits.lua`.
2. Add at minimum these runtime dependencies to `TraitsPage:GetRevisionTuple()`:
   - `InventoryRevision` — available consumable traits;
   - `EquipmentRevision` — equipped/mount equipment traits.
   Include an additional narrow resolved/profile revision only if the trait rows' condition/visibility output genuinely depends on it; do not fall back to broad `ProfileStateRevision` without tracing that dependency.
3. In `ProfileWindow:HandleRuntimeChange()`, derive a narrow `traitsChanged` condition from the relevant committed ChangeSet/revisions. At minimum Inventory and Equipment changes that can alter trait rows must mark `traitsPage` dirty.
4. If Traits is the active visible tab, refresh it once via `RefreshIfDirty()`; if hidden, mark dirty only and perform no rendering.
5. Do **not** solve this by broad-refreshing every Profile tab.

### Re-validation after fix

With Traits already built:

- add/remove an item carrying `consumableTrait` while Traits is visible -> Traits refreshes once and row/quantity availability is correct;
- add/remove the same while another tab/Profile window is hidden -> no Traits render until activation, then one refresh;
- equipment change which adds/removes an equipment trait -> Traits becomes stale and refreshes correctly when shown;
- unrelated Achievement/Skill-only mutations must not refresh Traits;
- unchanged Traits reactivation must still fast-path.

No configured commit status checks are present.

#64 remains open pending this fix.