## Goal
Audit Tasks 0–5 as one coherent implementation of the final Guild Requisitions page, execute the required behavior matrix, and fix **concrete defects only**.

Authoritative plan: `.docs/RPE2-Final-Guild-Requisitions-Page-Implementation-Plan.md`.

Depends on: #37, #38, #39, #40, #41, #42

Do not start until all preceding Guild Requisitions tasks are implemented and pushed/available in the working tree.

## Primary files
Audit all files changed by #37–#42, especially:

- `core/classes/GuildSetting.lua`
- `client/ui/editor/inspectors/page_InspectorGuildSetting.lua`
- `client/client_Guild.lua`
- `core/ui/prefabs/ShopEntry.lua`
- `RPEngine_Dev.toc`
- `client/character/guild/page_GuildRequisitions.lua`
- `client/character/guild/window_Guild.lua`
- `core/internal/profile/Guild.lua` only if a preceding task required a narrow compatibility edit

Inspect adjacent layout/tooltip/profile APIs where needed, but do not redesign them.

## Unlimited/limited semantics audit
Verify the canonical partition:

```text
characterLimit == 0 -> Guild Shop
characterLimit > 0  -> limited Requisitions
```

Test at minimum:

```text
omitted characterLimit -> normalizes to 1
characterLimit = 0 -> survives definition/editor round-trip
characterLimit = 1 -> limited
characterLimit = 3 -> limited
```

### Unlimited transaction matrix
Verify:

```text
affordable unlimited purchase -> succeeds
same unlimited purchase again -> succeeds while affordable
unlimited purchase -> no requisition usage ledger increment/write
unlimited insufficient currency -> rejected, item not awarded
unlimited invalid item/currency -> rejected without partial mutation
```

### Limited transaction matrix
Verify existing behavior remains intact:

```text
limit 1 first purchase -> succeeds + usage 1
limit 1 second purchase -> character-limit-reached
limit 3 purchases 1..3 -> succeed + ledger increments
limit 3 purchase 4 -> rejected
transaction failure -> existing rollback semantics preserved
```

Do not weaken the transaction layer to make UI testing pass.

## Daily Reward runtime audit
Verify automatic claiming is gone:

```text
PLAYER_ENTERING_WORLD with available reward -> no award
PLAYER_GUILD_UPDATE with available reward -> no award
GUILD_ROSTER_UPDATE with available reward -> no award
```

Verify explicit claim:

```text
available icon click -> one claim transaction
repeated click while pending -> no duplicate
second click after claim -> no duplicate
/reload after claim -> still claimed for current reset cycle
next daily reset -> becomes available again
```

Exercise both Item and Currency Daily Rewards where practical.

Confirm existing transaction markers/rollback/claim persistence remain authoritative.

## Reset-boundary audit
Verify one reset helper drives both runtime eligibility and UI timer.

Test/inspect:

```text
secondsRemaining comes from Blizzard daily reset API
visible HH:MM:SS follows same helper
claim cycle key derives from same reset boundary
cycle key changes when reset passes
page detects changed cycle and performs one full refresh
missing reset API -> clean unavailable state, no mixed local-midnight fallback
```

Confirm Profile claim persistence remains backward compatible and no unnecessary schema/root was introduced.

## ShopEntry audit
Verify `core/ui/prefabs/ShopEntry.lua` against `SpellbookEntry` visual behavior.

Test at multiple widths, especially the narrow limited panel and each Guild Shop column:

```text
short name -> full name shown
exact-fit name -> no unnecessary ellipsis
long name -> longest fitting prefix + "..."
resize narrower -> truncation recomputes
resize wider -> more/full text restored
very narrow width -> safe output/no bleed
```

Confirm:

- name is one line;
- cost is directly underneath;
- cost is one line and visually contained;
- full item name is preserved separately from rendered text;
- icon border/crop/hover match established prefab style;
- disabled state desaturates/subdues coherently;
- tooltip support remains functional.

## Guild Shop layout/pagination audit
Verify the left region is a Spellbook-style shop, not a list.

Required matrix:

```text
0 shop entries -> no visible entry rows, controls safe
1 shop entry -> first slot only
14 shop entries -> one full 2x7 page
15 shop entries -> two pages
28 shop entries -> two full pages
29 shop entries -> three pages
```

Confirm:

- exactly two columns;
- `GridLayoutGroup` owns entry placement;
- fixed `ShopEntry` pool is reused;
- no `ScrollLayout` is used for the Guild Shop;
- page clamping works after dataset/rank changes;
- Previous/Next disabled correctly at boundaries;
- page indicator is correct;
- long names never overlap the adjacent column;
- clicking an entry reaches `Guild:TryRequisition(...)` directly;
- unlimited entries remain visible after purchase;
- affordability/eligibility refreshes after purchase.

## Limited Requisitions panel audit
Verify the right region:

```text
uses UI.ScrollLayout
uses UI.ShopEntry rows
contains only characterLimit > 0
is one column/full panel width
shows scrollbar only when required
does not paginate
```

Test exhausted and unaffordable limited entries remain visible but disabled/subdued rather than disappearing.

Confirm `characterLimit > 1` stays enabled until the authoritative usage limit is reached.

## Header/tooltip/ticker audit
Verify final header exactly represents the agreed design:

```text
[Daily Reward ImageButton]  Guild Rank: <rank>
                            Daily Reset in HH:MM:SS
```

Confirm:

- Daily Reward control is `UI.ImageButton`;
- tooltip lists configured Item/Currency rewards with icons/names/amounts;
- unresolved definitions use safe fallback;
- tooltip remains available after claim;
- ordinary tooltip/page refresh performs no gameplay mutation;
- one ticker runs only while the page is visible;
- repeated show/hide does not accumulate tickers;
- ordinary ticker tick updates timer only;
- reset-cycle change triggers one full page refresh.

## No-extra-text audit
Search the final Requisitions page for visible legacy/provisional labels/messages.

The page must **not** render:

```text
Daily Rewards heading
Guild Shop heading
Requisitions heading
instruction/help text
status paragraph
empty-state prose
Selected/Select row status
Requisition button
action-result/status message
```

Allowed on-page functional text includes only:

```text
Guild Rank: <name>
Daily Reset in HH:MM:SS
ShopEntry item names
ShopEntry costs
Previous / Next / page indicator
```

Tooltip text is allowed.

## Refresh/state audit
Inspect `RequisitionsPage:Refresh()` and event/page callbacks for accidental mutation or redundant rebuilds.

Verify conceptually:

```text
resolve assigned rank/status once
resolve Daily Reward/reset state
update header
partition requisitions
refresh shop page
refresh limited list
```

Ordinary `Refresh()` must not:

- claim Daily Rewards;
- purchase requisitions;
- write Profile state;
- duplicate row click handlers indefinitely;
- rebuild the entire page tree unnecessarily.

## Window/load-order audit
Verify:

- `ShopEntry.lua` loads before `page_GuildRequisitions.lua`;
- no unrelated TOC ordering was changed;
- Guild window title remains exactly `Guild` after refresh;
- Requisitions/Progression/Admin tab builders still work;
- Guild window dimensions/show/hide/refresh routing remain intact.

## Existing hotfix/regression audit
Issue #36 must remain effective.

Exercise a manual Daily Reward claim containing multiple Profile writes and confirm it does not restore the previous synchronous full-config-refresh-per-write watchdog behavior.

Also verify no new second systems were introduced for:

```text
Guild Shop definitions
Requisition transaction/persistence
Daily Reward transaction
Daily reset timing
Tooltip handling
Ticker/task scheduling
Guild Rank assignment
```

## Final definition of done
- [ ] `characterLimit = 0` is authorable and means unlimited Guild Shop entry.
- [ ] Unlimited purchases bypass the usage ledger and remain repeatable while eligible/affordable.
- [ ] Positive limits preserve finite usage behavior and rollback semantics.
- [ ] Daily Rewards are manual click-to-claim only.
- [ ] Daily Reward claim and countdown use one Blizzard reset boundary.
- [ ] `ShopEntry` matches Spellbook styling with name above cost.
- [ ] Long item names truncate with `...` and never bleed across columns.
- [ ] Guild Shop is a paginated fixed two-column grid.
- [ ] Limited Requisitions are a one-column scroll view.
- [ ] Both regions use the same `ShopEntry` prefab and cost formatting.
- [ ] No separate purchase/selection UI remains.
- [ ] No extra headings/help/status/empty-state prose remain.
- [ ] Daily Reward tooltip remains available after claim.
- [ ] Visible-page ticker is lifecycle-safe and reset-aware.
- [ ] Guild window title remains `Guild`.
- [ ] Load order is coherent.
- [ ] Progression/Admin pages remain functional.
- [ ] Issue #36 configuration-refresh coalescing remains intact.
- [ ] No duplicate Guild Shop/Requisition/Daily Reward/reset subsystem was introduced.

## Coding-agent instructions
Treat current `FrontierDev/rpe2`, `.docs/RPE2-Final-Guild-Requisitions-Page-Implementation-Plan.md`, issue #36, and completed issues #37–#42 as authoritative. Inspect the actual final working tree rather than assuming task reports are correct. Execute every matrix above, fix concrete defects in this feature only, and do not redesign working adjacent systems or expand scope. Before marking complete, report the audit performed, files changed, validation results, and any unresolved deviation.