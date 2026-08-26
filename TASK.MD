### Follow-up correction: lazy tooltips alone are not sufficient

The previous diagnostic should **not** be interpreted as "move the existing expensive tooltip build from refresh to hover and stop there". That would remove the bulk Inventory-open/search hitch, but could simply create a smaller hitch the first time each item is hovered.

The measured scaling (~30 populated slots -> ~2.14 s refresh; ~5 populated slots -> ~309 ms refresh) strongly implicates eager per-slot tooltip construction, but the cost of a *single* `ItemTooltip:Build()` must be measured directly before considering this resolved.

#### Required tooltip fix

1. **Remove eager tooltip construction from `InventoryGridPage:Refresh()`**. The page should bind the current `resolvedItem` plus a lazy tooltip provider; `UI.Tooltip` already supports a function spec which is resolved when the tooltip is shown.
2. **Instrument a single lazy `ItemTooltip:Build()`** with timings. A hover must not introduce a visible hitch. Treat any single tooltip build >16 ms as a hard failure; practical target should be <=4 ms where possible.
3. **Optimize/cache the tooltip builder itself if it exceeds budget** rather than accepting hover lag. In particular, avoid repeated linear dataset/reference scans and repeated construction of static item metadata. Cache static tooltip data by item definition/configuration revision and exact modification/stack variant where appropriate.
4. Keep genuinely dynamic tooltip content (conditions/profile/event-dependent values) correct. Either evaluate only the dynamic fragments on hover or include the relevant runtime revision tuple in any full-tooltip cache; do not serve stale condition/profile state merely to make the cache fast.
5. Repeated hover of an unchanged item should reuse cached tooltip work and be effectively immediate.

This is in addition to the separate uncached display-snapshot blocker (~81.7 ms), which still needs indexed item-definition lookup.

Re-validation should therefore include both Inventory refresh timings **and** first/repeated hover timing for representative simple and complex items.