# RPE 2 — Item Spell Use and Tooltip Completeness

## Implementation Plan

**Target branch:** `dev`  
**Companion document:** `.docs/RPE2-Item-Spell-Use-and-Tooltip-PDD.md`

---

## 1. Implementation Constraints

Implement only the following scope:

1. Consumable items may reference and cast one Spell.
2. Weapon/armor items may reference one on-use Spell while equipped.
3. Item tooltips show only the resolved Spell description plus configured cooldown for that on-use Spell.
4. Embedded item Trait Aura descriptions appear on item tooltips.
5. Item skill-bonus `Equip:` lines appear after item `Equip:` stat lines.

Do not create a parallel item-effect executor. Spell effects continue through the existing Spellcasting lifecycle.

Before editing each file, read its current `dev` version and trace all current call sites; the paths below are based on the inspected repository state and should not be treated as permission for architectural expansion if the code has changed.

---

## 2. Step 1 — Extend the Item Model

### Files

```text
core/classes/Item.lua
```

### Changes

Add:

```lua
useSpellRef = nil
```

to `Item.New()`.

In `Item.Merge()`:

- normalize `useSpellRef` through the existing item-reference normalization helper;
- retain it only for `consumable`, `weapon`, and `armor` item types;
- clear it for unsupported item types.

In `Item.ToTable()`:

- serialize `useSpellRef`.

Do not alter `consumableTrait` or `equipmentTrait` semantics.

### Regression checks

Verify existing Item records with no `useSpellRef` normalize identically to before.

Verify changing an authored item from `consumable`/`weapon`/`armor` to an unsupported item type removes the stale use reference.

---

## 3. Step 2 — Dataset Schema and Reference Integrity

### Files

```text
core/internal/database/Dependecies.lua
core/internal/database/DatasetSchema24.lua        [new]
RPEngine_Dev.toc
```

### Dependency changes

In `getItemSourceRefs(item)` add:

```lua
item.useSpellRef
```

when non-empty.

Extend item reference pruning so deletion of:

- an individual referenced Spell; or
- the entire referenced Dataset

clears `item.useSpellRef`.

Inspect both collection-entry deletion and full-dataset deletion paths; do not update dependency discovery without matching pruning behavior.

### Schema 24

Follow the existing `DatasetSchema23.lua` pattern:

- advance `RPEngineDatasetDB._schema` to `24`;
- normalize existing Item records through the current Item class boundary once the Item class is loaded;
- normalize imported dataset Item records at the import boundary if the generic import normalization does not already guarantee the new field;
- recompute dependencies after normalization/import when required.

Do not rescan every Item on ordinary reads after the schema migration has completed.

### TOC ordering

`DatasetSchema24.lua` must load after:

```text
core/classes/Item.lua
core/internal/database/DatasetSchema23.lua
```

and after the dependency module it invokes.

### Regression checks

Deterministic cases:

```text
same-dataset Spell reference -> no external dependency
cross-dataset Spell reference -> dependency added
clear useSpellRef -> dependency removed if otherwise unused
delete referenced Spell -> useSpellRef cleared
delete referenced Dataset -> useSpellRef cleared
rename Dataset -> qualified reference rewritten by existing generic rewrite path
```

---

## 4. Step 3 — Add the Data Editor Control

### Files

```text
client/ui/editor/inspectors/item/page_InspectorItemBehavior.lua
client/ui/editor/inspectors/page_InspectorItem.lua
client/ui/editor/inspectors/item/page_InspectorItemShared.lua   [only if helper reuse is required]
```

### UI

On the Item **Behavior** page add an `On-Use Spell` selector.

Prefer the existing Dataset + entry dropdown/reference-selector idiom used by other inspectors. Persist only the dataset-qualified Spell reference.

The control is visible/enabled only when:

```lua
item.itemType == "consumable"
or item.itemType == "weapon"
or item.itemType == "armor"
```

Refresh logic must:

- repopulate available Spell definitions when configuration changes;
- restore the selected qualified reference;
- disable/clear the control when no Item is selected;
- not mutate data while `_refreshingItemInspector` is true.

### Regression checks

Verify:

```text
Consumable -> selector visible
Weapon -> selector visible
Armor -> selector visible
Material -> selector hidden/disabled
Modification -> selector hidden/disabled
Changing type away from supported type clears stale useSpellRef
Cross-dataset selection persists after editor refresh
```

---

## 5. Step 4 — Extract Generic Spell Activation

### Files

```text
client/client_Targeting.lua
```

### Current path to preserve

Current action-bar activation performs:

```text
ActivateActionBarSpell
    -> ResolveSpellActivationSnapshot(includeTargetCandidates = true)
    -> immediate OnSpellcastStart if no target groups
       OR
       PendingSpellTargeting
    -> ConfirmPendingSpellTargeting
    -> executeConfirmedSpellTargeting
    -> OnSpellcastStart
```

### Refactor

Extract this behavior to a source-agnostic entry point, for example:

```lua
Client:ActivateSpellReference(spellRef, options)
```

Keep:

```lua
Client:ActivateActionBarSpell(spellRef)
```

as a wrapper so existing action-bar call sites remain unchanged.

`options` should carry only activation-source metadata/callback information needed by the caller; do not duplicate Spell conditions or override normal Spell state.

Suggested runtime-only shape:

```lua
{
    sourceType = "action_bar" | "item",
    sourceContext = <opaque caller-owned table>,
    onCastAccepted = <optional function>,
}
```

If avoiding callbacks is preferred, store a structured source descriptor and dispatch through one internal accepted-cast hook. The important requirement is that the targeting flow can carry the source context until the actual cast attempt.

### Pending targeting

Extend `PendingSpellTargeting` with the activation-source context.

`ConfirmPendingSpellTargeting()` / `executeConfirmedSpellTargeting()` must preserve it when they finally call `OnSpellcastStart()`.

### Acceptance hook timing

Invoke the source commit hook only when `OnSpellcastStart()` reports a successful accepted cast.

Do not invoke it when:

```text
activation snapshot fails
targeting has no legal target
user cancels targeting
target state becomes invalid
OnSpellcastStart fails
```

### Regression checks

Exercise existing action-bar casts through the wrapper:

```text
instant self-target/no-target Spell
targeted Spell
multi-target-group Spell
cast-time Spell
cancelled targeting
Spell on cooldown
insufficient resources
failed conditions
```

No action-bar behavior should change.

---

## 6. Step 5 — Implement the Item Use Service

### Files

```text
client/client_ItemUse.lua                           [new]
RPEngine_Dev.toc
client/character/inventory/Inventory.lua            [only if a small source-validation helper is warranted]
core/internal/profile/Equipment.lua                 [only if a small equipped-source helper is warranted]
```

### Namespace/API

Create a narrow service, for example:

```lua
Addon.Client.ItemUse
```

Suggested public entry points:

```lua
ItemUse:UseInventoryItem(sourceIndex, expectedStackIdentity)
ItemUse:UseEquippedItem(scope, slotKey)
```

### Common validation

Resolve:

```text
item definition
itemRef
useSpellRef
referenced Spell
```

Reject unsupported/missing/inactive state before starting targeting.

### Inventory source token

Capture enough identity to detect a stale inventory source after targeting:

```lua
{
    mode = "inventory",
    sourceIndex = sourceIndex,
    stackIdentity = expectedStackIdentity,
    itemRef = itemRef,
}
```

Do not trust `sourceIndex` alone because inventory mutation/reordering can move stacks while targeting is open.

At commit, locate/validate the expected stack identity and ensure quantity is still positive before removal.

If the existing Inventory indexes do not expose a safe lookup helper, add one small read-only helper rather than reimplementing stack identity in ItemUse.

### Equipment source token

Capture:

```lua
{
    mode = "equipment",
    scope = "character",
    slotKey = normalizedSlotKey,
    itemRef = itemRef,
}
```

At commit, call the existing Profile/Equipment getter and verify the same `itemRef` remains in the same slot.

### Spell activation

Call only the generic activation API from Step 4:

```lua
Client:ActivateSpellReference(item.useSpellRef, {
    sourceType = "item",
    sourceContext = token,
    onCastAccepted = ...,
})
```

Do not call effect components, targeting helpers, cooldown APIs or resource mutation directly from ItemUse.

### Consumable commit

After successful cast start:

1. Revalidate source token.
2. Apply bind-on-use through the existing soulbound mutation path when required.
3. Remove exactly `1` from the inventory stack through `Inventory.RemoveItem()` or the canonical equivalent.
4. Let normal Inventory/Runtime mutation notifications refresh UI.

Ensure bind/remove operations do not leave a partially mutated stack if a revalidation fails.

Where the Runtime transaction system can safely combine the item mutation work, use it; do not nest incompatible transaction ownership around `OnSpellcastStart()` without tracing its existing runtime behavior.

### Equipment commit

After successful cast start:

1. Revalidate same equipped entry.
2. Apply bind-on-use state if the existing equipment representation/API supports the mutation cleanly.
3. Do not remove the item.

If equipment soulbinding currently lacks a canonical mutation API, add the smallest Profile/Equipment helper needed rather than directly editing SavedVariables from ItemUse.

### Failure reasons

Return stable internal reasons such as:

```text
missing-item
inactive-item
invalid-item-type
stale-source
not-equipped
missing-use-spell
invalid-use-spell
cast-rejected
```

### TOC ordering

Load `client_ItemUse.lua` after:

- Inventory/Profile APIs it reads;
- Spellcasting lifecycle/targeting generic activation API.

It must load before UI files that call it.

---

## 7. Step 6 — Inventory Use UI

### Files

```text
client/character/inventory/page_Inventory.lua
```

### Changes

Extend `EnsureItemContextMenu()` and `ShowItemContextMenu()`.

Show `Use` when all presentation-level prerequisites are true:

```text
resolved item exists
Dataset active/not missing
itemType == consumable
item.useSpellRef is non-empty
source stack exists
```

On invoke:

```lua
ItemUse:UseInventoryItem(resolved.sourceIndex, resolved.stackIdentity)
```

Do not consume the item in the UI callback.

Do not make UI visibility the authority; ItemUse repeats all validation.

### Regression checks

```text
ordinary consumable without useSpellRef -> no Use action
usable consumable -> Use shown
missing/inactive definition -> Use unavailable
cancel targeted cast -> stack unchanged
accepted instant cast -> quantity decreases by one
accepted cast-time cast -> quantity decreases by one at cast start
interrupted cast-time cast -> quantity does not return
failed cast -> quantity unchanged
```

---

## 8. Step 7 — Equipment On-Use UI

### Files

```text
client/character/profile/page_ProfileEquipmentStats.lua
```

### Current behavior

Right-click currently calls the unequip path immediately.

### Change

Add/reuse a `UI.ContextMenu` for equipped character items.

For an item with `useSpellRef`:

```text
Use
Unequip
```

For other equipment:

```text
Unequip
```

The `Use` action calls:

```lua
ItemUse:UseEquippedItem("character", slotKey)
```

The `Unequip` action calls the same existing unequip API currently used by right-click.

Do not change left-click selection behavior.

### Regression checks

```text
ordinary equipment can still be unequipped
equipment with on-use Spell can be used
item replaced while targeting -> commit rejected
item unequipped while targeting -> commit rejected
use does not remove equipment
cooldown prevents repeated use according to referenced Spell
```

---

## 9. Step 8 — Add Compact Spell Use Text to Item Tooltips

### Files

```text
client/ui/tooltips/tooltip_Item.lua
```

### New helper

Add a helper that:

1. reads `item.useSpellRef`;
2. resolves it through `Registry:ResolveSpellReference()`;
3. builds Spell description detail with the resolved Dataset/Spell/ref;
4. calls `Spellcasting.DescriptionBuilder:BuildTooltipData(..., { deferGeneration = false })`;
5. takes only `descriptionText`;
6. reads the configured authored Spell cooldown;
7. formats the one item line.

Conceptually:

```text
Use: {descriptionText}. ({cooldown} turn cooldown)
```

Avoid doubled punctuation when the description already ends in punctuation.

If cooldown is zero/nil, omit the suffix.

### Explicit exclusions

Do **not** call `Tooltips.Spell:Build()` and splice its lines into the Item tooltip.

Do not display from the referenced Spell:

```text
cost
cast-time row
conditions
charges
runtime cooldown remaining
Aura detail sections
Spell title
```

### Error handling

If the referenced Spell cannot resolve, do not generate misleading effect text. Prefer a clear unavailable/missing `Use:` error line consistent with existing item missing-reference behavior, while the editor/dependency system should normally prevent this state.

### Cache

Increment `TOOLTIP_CACHE_VERSION`.

Reuse the existing configuration/profile/Aura runtime revision cache key; no new global invalidation system is required.

### Deterministic tooltip cases

```text
templated heal with range -> current resolved 16-32 style range
Spell with cooldown -> suffix displayed
Spell without cooldown -> no suffix
Spell with resource costs -> costs absent from Item tooltip
Spell with cast time -> cast-time line absent
Spell with conditions -> condition lines absent
Spell with charges -> charge line absent
Spell that applies Aura -> Spell's linked Aura section absent from item-use line
```

---

## 10. Step 9 — Render Embedded Trait Aura Sections on Items

### Files

```text
client/ui/tooltips/tooltip_Item.lua
```

### Refactor

Replace the description-only embedded Trait helpers with tooltip-data helpers.

Current conceptual path:

```text
Item tooltip
    -> TraitDescriptionBuilder:BuildDescription()
    -> descriptionText only
```

New path:

```text
Item tooltip
    -> TraitDescriptionBuilder:BuildTooltipData()
    -> descriptionText
    -> auraSections
```

Use the same detail structure currently supplied for equipment/consumable embedded Traits, including Dataset and caster context.

### Rendering

Keep the current summary line:

```text
Equip: <Trait description>
```

or:

```text
Use: <Trait description>
```

Then append each Aura section using the same presentation semantics as `client/ui/tooltips/tooltip_Trait.lua`:

```text
<blank separator>
<Aura icon/name>
<Aura templated description>
```

Deduplication remains the responsibility of `TraitDescriptionBuilder`; Item tooltip should not reimplement Aura-reference traversal.

### Coverage

Verify Aura sections generated from:

```text
trait.automaticAuras
trait.events[] with apply_aura effect
```

for both `equipmentTrait` and `consumableTrait`.

### Regression checks

```text
Trait with no Aura -> tooltip unchanged except intended ordering
Trait with one automatic Aura -> section shown
Trait with duplicate references -> no duplicate section
Trait apply_aura event -> section shown
Authored Trait description + Aura -> authored summary and Aura detail both shown
```

---

## 11. Step 10 — Reorder Skill Bonus Lines

### Files

```text
client/ui/tooltips/tooltip_Item.lua
```

### Change

In `ItemTooltip:Build()`, move:

```lua
appendSkillBonusLines(lines, item)
```

so it executes after:

```lua
appendEquipStatLines(lines, item, values)
```

for normal equipment/item rendering.

Retain the current green `Equip:` skill formatting and skill-name resolution.

Revisit the spacer condition so moving the lines does not introduce duplicate blank rows.

### Expected order

```text
+10 Strength                 -- ordinary/base stat presentation, where applicable

Equip: Increases ...         -- generated equip-stat effect line(s)
Equip: Increases your skill in Alchemy by 5.
Equip: <embedded equipment Trait summary>
Use: <Spell description>. (10 turn cooldown)
```

### Regression checks

Verify items with:

```text
skill bonuses only
equip stats only
both equip stats and skill bonuses
equipment Trait + skill bonus
on-use Spell + skill bonus
```

have no extra/missing separators.

---

## 12. Step 11 — Call-Site and Regression Audit

Before finalizing, search every modified public/API symbol.

### `Item` API

Audit:

```text
Item.New
Item.FromTable / Merge
Item.ToTable
item-type defaulting
Dataset import/export
Data Editor commits
Dependency discovery/pruning
```

### Generic Spell activation

Search all references to:

```text
ActivateActionBarSpell
PendingSpellTargeting
ConfirmPendingSpellTargeting
executeConfirmedSpellTargeting
OnSpellcastStart
```

Ensure the action bar and NPC/autopilot explicit-caster paths have not accidentally been routed through item-specific commit semantics.

### Inventory API

Audit any new helper plus:

```text
Inventory.RemoveItem
Inventory.SetItemSoulbound
Inventory.GetDisplaySnapshot
stack identity/index maintenance
Runtime inventory revision notifications
```

### Equipment API

Audit:

```text
GetEquippedEntryByScope
UnequipSlotToInventoryByScope
soulbound persistence
profile equipment revisions
```

### Tooltip builders

Audit:

```text
TraitDescriptionBuilder:BuildDescription
TraitDescriptionBuilder:BuildTooltipData
Spellcasting.DescriptionBuilder:BuildTooltipData
ItemTooltip:Build
```

Do not change the normal standalone Spell/Trait tooltip formats.

---

## 13. Step 12 — Validation Matrix

### Pure/data tests

Where the project test harness is unavailable, exercise deterministic Lua logic through isolated mocks/stubs.

#### Item normalization

```text
valid consumable useSpellRef retained
valid weapon/armor useSpellRef retained
unsupported type clears useSpellRef
ToTable round-trip retains useSpellRef
```

#### Dependencies

```text
cross-dataset Spell reference discovered
Spell deletion prunes item reference
Dataset deletion prunes item reference
```

#### Tooltip text

Mock Registry/DescriptionBuilder and verify exact line order/content.

Expected representative output:

```text
Minor Healing Potion
Use: Heal yourself for 16-32 health. (10 turn cooldown)
```

Verify no Spell cost/cast-time/condition/charge lines leak into Item tooltip.

#### Trait Aura sections

Mock `TraitDescriptionBuilder:BuildTooltipData()` with one/multiple Aura sections and verify they are rendered after the relevant embedded Trait summary.

### In-game integration cases

1. **Instant self-heal consumable**
   - right-click -> Use;
   - Spell resolves;
   - effect executes;
   - one item removed;
   - cooldown starts.

2. **Targeted consumable**
   - Use enters targeting;
   - cancel -> no removal;
   - Use again, confirm -> one removal.

3. **Cast-time consumable**
   - item removed at accepted cast start;
   - interrupt does not refund item.

4. **Equipment on-use**
   - context menu shows Use/Unequip;
   - effect casts without removing item;
   - cooldown enforced.

5. **Stale equipment**
   - start targeting;
   - unequip/replace item;
   - confirm -> item-use commit rejected.

6. **Shared Spell reference**
   - two items reference same Spell;
   - using one places that Spell on cooldown for the caster;
   - second item respects the same cooldown.

7. **Trait Aura tooltip**
   - equipment/consumable embedded Trait applies Aura;
   - item tooltip shows Trait summary and Aura templated detail.

8. **Skill-bonus ordering**
   - item with normal equip stats + skill bonus;
   - skill line appears underneath equip stat lines.

---

## 14. Expected Modified File Set

Primary expected files:

```text
core/classes/Item.lua
core/internal/database/Dependecies.lua
core/internal/database/DatasetSchema24.lua                 [new]
client/client_Targeting.lua
client/client_ItemUse.lua                                  [new]
client/ui/tooltips/tooltip_Item.lua
client/character/inventory/page_Inventory.lua
client/character/profile/page_ProfileEquipmentStats.lua
client/ui/editor/inspectors/item/page_InspectorItemBehavior.lua
client/ui/editor/inspectors/page_InspectorItem.lua
RPEngine_Dev.toc
```

Possible narrow helper changes only if required after reading current call paths:

```text
client/character/inventory/Inventory.lua
core/internal/profile/Equipment.lua
client/ui/editor/inspectors/item/page_InspectorItemShared.lua
```

Do not modify standalone Spell execution/components merely to support item use unless investigation reveals a concrete missing generic capability.

---

## 15. Completion Criteria

Implementation is complete when all of the following are true:

```text
Item definitions can author one qualified useSpellRef.

Consumables expose a Use action and cast the referenced Spell through the normal targeting/cast lifecycle.

One consumable is removed only after a successful cast start.

Cancelling or rejecting a targeted item Spell consumes nothing.

Weapon/armor on-use effects work only while the same item remains equipped.

Equipment use never removes the item.

Item-origin casts obey the referenced Spell's normal conditions, resources, targeting, cast time and cooldown behavior.

Action-bar spellcasting has no regression after generic activation extraction.

Item tooltips show only the referenced Spell's resolved description plus configured cooldown suffix for the on-use effect.

Full Spell tooltip metadata does not leak into the Item tooltip.

Embedded item Traits that apply Auras show the templated Aura detail section on the Item tooltip.

Skill-bonus Equip lines appear beneath item Equip stat lines.

Cross-dataset on-use Spell references participate correctly in dependency discovery and deletion pruning.

Existing items with no on-use Spell continue to load, export, display and behave unchanged.
```

---

## 16. Architectural Guardrail

After implementation, review the diff specifically for accidental expansion.

The intended dependency direction is:

```text
Item definition
    -> useSpellRef
        -> existing Spell definition

Inventory/Equipment UI
    -> ItemUse service
        -> generic Spell activation
            -> existing Spellcasting lifecycle
```

It must **not** become:

```text
Item
    -> copied Spell components
    -> custom item targeting
    -> custom item cooldowns
    -> custom item combat execution
```

The latter would duplicate mature systems and is outside this task.