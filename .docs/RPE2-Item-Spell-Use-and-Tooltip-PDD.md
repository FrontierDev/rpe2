# RPE 2 — Item Spell Use and Tooltip Completeness

## Product Design Document

**Status:** Draft  
**Target:** `FrontierDev/rpe2` `dev` branch  
**Scope:** consumable spell-use items, equipment on-use spells, item trait aura descriptions, item skill-bonus tooltip ordering

---

## 1. Purpose

RPE 2 items already support persistent equipment statistics, skill bonuses, embedded equipment/consumable Traits, modifications, conditions, binding and inventory state. Spells already own the complete cast lifecycle: conditions, targeting, cast time, resource costs, cooldowns, components, aura application, logging and event synchronization.

This change connects those systems without introducing a second item-effect engine.

It adds:

1. **Consumable items that cast a Spell when used.**
2. **Equipped items with an on-use Spell.**
3. **Aura detail sections on item tooltips when an embedded item Trait applies Auras.**
4. **Skill-bonus `Equip:` lines after the item's existing `Equip:` stat lines.**

The central design rule is:

> An item references a Spell; the Spell remains the sole definition and executor of the on-use gameplay effect.

---

## 2. Current Architecture

### 2.1 Item definitions

`core/classes/Item.lua` already normalizes and serializes fields including:

```lua
stats
skillBonuses
conditions
consumableTrait
equipmentTrait
```

There is currently no Spell reference representing an explicit manual item use.

`consumableTrait` and `equipmentTrait` are not substitutes for this feature. They are embedded Trait payloads and participate in the Trait/event-phase system. A manually activated spell should use the existing spellcasting system instead.

### 2.2 Item skill bonuses already exist

`client/ui/tooltips/tooltip_Item.lua` already renders item `skillBonuses` as green lines such as:

```text
Equip: Increases your skill in Alchemy by 5.
```

The defect is ordering: `appendSkillBonusLines()` currently runs before `appendEquipStatLines()`.

No new skill-bonus data model is required.

### 2.3 Trait aura descriptions already exist

`client/traits/DescriptionBuilder.lua` already returns:

```lua
{
    descriptionText = ...,
    auraSections = { ... },
}
```

The Aura sections are generated through `AuraDescriptionBuilder` and contain the templated Aura name/description.

`client/ui/tooltips/tooltip_Trait.lua` already consumes those Aura sections correctly.

The item tooltip does not. Its embedded-Trait helpers call `DescriptionBuilder:BuildDescription()`, which returns only the one-line Trait description and discards `auraSections`.

Therefore the missing Aura text is a presentation integration defect, not a missing Aura-description feature.

### 2.4 Spell activation already has the required rules

`Client:ResolveSpellActivation()` resolves an arbitrary Spell reference against the active caster and active event. It does not require that the Spell be present in the player's spellbook.

The activation snapshot/cast lifecycle already enforces:

- active event/session;
- caster turn ownership;
- existing cast state;
- casting-prevention Auras;
- Spell conditions;
- resource costs;
- global cooldown;
- Spell cooldown/charges;
- targeting rules and candidate selection;
- cast time;
- component execution;
- cooldown application;
- spellcast synchronization and lifecycle logging.

This is the correct execution path for item-origin Spells.

### 2.5 Action-bar activation is reusable but named too narrowly

`Client:ActivateActionBarSpell(spellRef)` already performs the common activation workflow:

```text
Build activation snapshot
    ↓
Validate cast
    ↓
If targeting is required, open targeting UI
    ↓
Confirm targets
    ↓
OnSpellcastStart()
```

Despite its name, the implementation is not inherently action-bar-specific.

Item use should not duplicate this targeting/casting logic. The workflow should be extracted behind a generic Spell activation entry point, while `ActivateActionBarSpell()` remains as a compatibility wrapper.

### 2.6 Inventory has no Use action today

The inventory item context menu currently supports:

```text
Equip
Modify
Delete
```

There is no general item-use action.

### 2.7 Equipped slots currently right-click to unequip directly

The character equipment page currently uses right-click as an immediate unequip action. Equipment on-use effects therefore need an explicit interaction surface.

---

## 3. Item Data Model

Add one optional field to `Item`:

```lua
useSpellRef = nil
```

Example:

```lua
{
    id = "minor_healing_potion",
    name = "Minor Healing Potion",
    itemType = "consumable",
    useSpellRef = "core:minor_healing_potion_use",
}
```

Equipment example:

```lua
{
    id = "gnomish_defibrillator",
    name = "Gnomish Defibrillator",
    itemType = "armor",
    useSpellRef = "engineering:defibrillate",
}
```

### 3.1 Why one `useSpellRef`

Do not add separate fields such as:

```lua
consumableSpellRef
equipmentUseSpellRef
```

Both cases mean the same thing: manual use of an item activates a Spell. One field gives one serialization rule, one editor control, one dependency rule, one tooltip renderer and one activation service.

### 3.2 Supported item types

For this phase, `useSpellRef` is meaningful on:

```text
consumable
weapon
armor
```

It is cleared/ignored for:

```text
material
modification
none
```

A weapon or armor Spell may only be activated while that item is actually equipped.

### 3.3 Existing embedded Traits remain independent

`consumableTrait` and `equipmentTrait` continue to work exactly as they do now.

An item may technically contain both an embedded Trait and `useSpellRef`. They are independent effects. The manual `Use` action activates only `useSpellRef`; it does not manually execute the embedded Trait.

---

## 4. Dataset Schema and Dependencies

### 4.1 Item normalization

Extend `Item.New`, `Item.Merge` and `Item.ToTable` to normalize/serialize `useSpellRef` using the same qualified-reference conventions used by other Item references.

Introduce the next dataset schema marker (`24`) so existing/imported datasets pass through the current Item normalization boundary with the new canonical field supported.

### 4.2 Dependency discovery

`core/internal/database/Dependecies.lua` already discovers Item references for:

- damage schools;
- slots;
- stats;
- skills;
- embedded Trait stats/skills/Auras.

Add `item.useSpellRef` to `getItemSourceRefs()`.

This ensures an item in Dataset A correctly declares Dataset B as a dependency when:

```lua
useSpellRef = "dataset_b:some_spell"
```

### 4.3 Reference deletion/pruning

When a referenced Spell or its Dataset is deleted, the existing dependency-pruning paths must clear the affected `useSpellRef` rather than leaving a dangling reference.

Dataset rename/reference rewriting already walks authored tables recursively and therefore does not require a special-case rewrite for this field.

---

## 5. Data Editor

Use the existing Item inspector **Behavior** page as the authoring surface.

Add:

```text
On-Use Spell
[ Dataset ] [ Spell ]
```

or the equivalent existing qualified-reference selector pattern.

The field is visible/enabled only for:

```text
Consumable
Weapon
Armor
```

Selecting an unsupported item type clears `useSpellRef` during normal item normalization/type-default handling.

Do not put the field in the existing Consumable Trait page. That page authors embedded Trait behavior and activation phases; on-use Spell casting is a separate system.

The selector must list resolvable Spell definitions and store a dataset-qualified Spell reference.

---

## 6. Generic Spell Activation Entry Point

Refactor the action-bar entry point into a generic activation function, conceptually:

```lua
Client:ActivateSpellReference(spellRef, options)
```

`ActivateActionBarSpell()` becomes a thin wrapper:

```lua
function Client:ActivateActionBarSpell(spellRef)
    return self:ActivateSpellReference(spellRef, {
        sourceType = "action_bar",
    })
end
```

The generic function retains the current behavior for:

- activation snapshots;
- target candidate construction;
- target-group UI;
- pending targeting;
- target confirmation;
- `OnSpellcastStart()`.

### 6.1 Activation source context

The generic activation flow must be able to carry non-serialized source context until the cast is actually accepted.

For item use, use a structured source token rather than consuming/mutating the item immediately.

Conceptually:

```lua
{
    sourceType = "item",
    itemUseToken = {
        mode = "inventory", -- or "equipment"
        itemRef = "core:minor_healing_potion",
        sourceIndex = 12,
        stackIdentity = "...",
        scope = nil,
        slotKey = nil,
    },
}
```

For equipment:

```lua
{
    mode = "equipment",
    itemRef = "core:gnomish_defibrillator",
    scope = "character",
    slotKey = "trinket1",
}
```

Pending targeting must retain this source context so confirming targets can commit the correct item use.

---

## 7. Item Use Service

Add a focused client service, for example:

```text
client/client_ItemUse.lua
```

Namespace:

```lua
Addon.Client.ItemUse
```

Responsibilities:

```text
Resolve item source
Validate source still exists
Resolve useSpellRef
Validate item type/use rules
Request generic Spell activation
Commit use after cast acceptance
Consume inventory item when required
Apply bind-on-use semantics through existing state APIs
Return stable failure reasons to UI
```

The service must not execute Spell components itself.

### 7.1 Inventory consumable validation

Before activation:

```text
Inventory source still exists
Dataset/item definition still resolves
Dataset is active
Item is a consumable
Item has a valid useSpellRef
Referenced Spell resolves
Quantity >= 1
```

Before commit, revalidate the source token because targeting may have remained open while inventory state changed.

### 7.2 Equipment validation

Before activation and again before commit:

```text
Profile equipment entry still exists
The same itemRef is still equipped in the same scope/slot
Item definition is weapon or armor
Item has a valid useSpellRef
Referenced Spell resolves
```

An unequipped/replaced item cannot complete an on-use activation that was started from stale UI state.

---

## 8. Consumable Commit Semantics

A consumable must **not** be removed when the user merely selects `Use`.

Targeted Spell flow can be cancelled. Therefore:

```text
Click Use
    ↓
Validate item
    ↓
Enter Spell targeting, if required
    ↓
User confirms targets
    ↓
OnSpellcastStart() succeeds
    ↓
Consume exactly one item
```

If validation fails, targeting is cancelled, or `OnSpellcastStart()` fails, no item is consumed.

If the Spell has a non-zero cast time and is later interrupted, the consumable remains consumed. The item was committed when the cast began.

Consumption uses the existing Inventory mutation API and must preserve normal stack behavior/revision notifications.

### 8.1 Bind on use

Where an on-use item has `bindingFlag == "bind_on_use"`, use the existing soulbound mutation path as part of the accepted-use transaction/state change.

For a consumed stack, normal stack semantics apply to the remaining record.

---

## 9. Spell Rules for Item-Origin Casts

Item-origin casts do not receive a parallel ruleset.

They use the referenced Spell exactly as authored, including:

```text
conditions
resource costs
cast time
targeting
components
cooldown
charges
global cooldown behavior
Aura interactions
```

If a potion should have no mana/resource cost, its referenced Spell should simply define no resource cost.

This keeps one source of truth for gameplay behavior.

### 9.1 Cooldown identity

Cooldown state is currently keyed by caster and Spell reference.

Therefore two items that reference the same Spell intentionally share that Spell's cooldown state.

If two items require independent cooldowns, author separate Spell definitions for them.

---

## 10. Inventory and Equipment UI

### 10.1 Inventory

Extend the inventory right-click context menu.

For a usable consumable:

```text
Use
Delete
```

Other existing actions remain applicable where relevant.

`Use` calls the Item Use service. The UI must not remove inventory state itself.

### 10.2 Equipped items

Replace the current immediate right-click unequip behavior for character equipment slots with a small context menu so on-use equipment is discoverable and does not require an additional mouse gesture.

For an equipped item with `useSpellRef`:

```text
Use
Unequip
```

For ordinary equipped items:

```text
Unequip
```

The context menu calls the Item Use service with the equipment scope/slot. It does not call Spellcasting directly.

---

## 11. Item Spell Tooltip Presentation

An item with `useSpellRef` must **not** embed the full Spell tooltip.

The full Spell tooltip currently includes resource costs, charges, cast time, cooldown state, conditions and linked Aura sections. Those are intentionally omitted from the item presentation.

Resolve the Spell and ask `Spellcasting.DescriptionBuilder:BuildTooltipData()` for the canonical resolved description. For a templated Spell, this resolves the current tooltip template and dynamic value tokens using the normal caster context.

Render only:

```text
Use: <resolved spell description>. (<configured cooldown> turn cooldown)
```

Example:

```text
Minor Healing Potion
Use: Heal yourself for 16-32 health. (10 turn cooldown)
```

If the referenced Spell has no positive cooldown:

```text
Use: Heal yourself for 16-32 health.
```

### 11.1 Deliberately omitted Spell metadata

Do not add these to the item tooltip merely because they exist on the Spell:

```text
Spell name
resource cost
cast-time line
charge count
current cooldown remaining
condition lines
global cooldown text
linked Spell Aura detail sections
```

The item shows the resolved Spell description plus configured cooldown suffix only.

Other independent item information (binding, item stats, item Traits, item description, modifications, etc.) remains visible normally.

### 11.2 Tooltip caching

The Item tooltip already keys dynamic output against configuration/profile/Aura revisions. Reuse that mechanism.

Bump the item tooltip cache version so the new line ordering/format does not reuse stale static tooltip entries.

---

## 12. Embedded Trait Aura Descriptions on Items

Replace the item tooltip's embedded-Trait description-only path with the same `BuildTooltipData()` contract already used by `tooltip_Trait.lua`.

For each embedded Trait:

1. Render the existing summary as `Equip:` or `Use:`.
2. Read `auraSections` from the same tooltip data.
3. Render each deduplicated Aura section beneath the Trait summary using the current Trait-tooltip visual pattern:
   - Aura name/icon heading;
   - templated Aura description.

This applies to Aura sections produced from the embedded Trait's:

```text
automaticAuras
apply_aura event effects
```

The implementation should use the existing Trait/Aura description builders; it must not reconstruct Aura sentences inside `tooltip_Item.lua`.

---

## 13. Skill Bonus Ordering

The intended item tooltip ordering is:

```text
...base item combat/stat lines...

Equip: <item stat effect>
Equip: <item stat effect>
Equip: Increases your skill in <Skill> by <N>.
Equip: <equipment Trait summary>

Use: <on-use Spell description>. (<N> turn cooldown)
Use: <consumable Trait summary>
...Trait Aura detail sections where applicable...
```

The critical rule is:

> Item `skillBonuses` must be rendered after `appendEquipStatLines()` so skill bonuses appear underneath the `Equip:` stat block.

No change to the `skillBonuses` schema or resolution rules is required.

---

## 14. Failure Handling

Item-use activation should expose stable failure reasons internally, including:

```text
missing-item
inactive-item
not-consumable
not-equipped
stale-source
missing-use-spell
invalid-use-spell
spell-unavailable
cast-rejected
```

The first implementation may surface these through existing UI/debug messaging rather than introducing a new error window.

A failed item action must never partially consume/bind the item.

---

## 15. Out of Scope

This change does not add:

```text
items with multiple selectable on-use Spells
item-specific cooldown state separate from Spell cooldowns
on-hit / proc / chance-on-hit equipment Spells
passive Spell grants from equipment
using combat Spells outside an active RPE event
new Spell component types
new Aura templating rules
new skill-bonus storage
item actions on the action bar
```

Those can be layered later without changing the one-item-reference-to-one-Spell model.

---

## 16. Principal Architectural Decisions

- Add one optional `Item.useSpellRef` field.
- Reference a real Spell rather than embedding/copying Spell components into the Item.
- Keep embedded Item Traits separate from manual Spell use.
- Extract the current action-bar activation workflow into a generic Spell activation entry point.
- Carry an item source token through targeting and commit use only after successful cast start.
- Consume one consumable only after the cast is accepted; cancellation/failure consumes nothing.
- Revalidate equipment at commit so stale targeting cannot activate an unequipped item's Spell.
- Reuse normal Spell conditions, resource costs, targeting, cooldowns, cast time, components and synchronization.
- Use Spell DescriptionBuilder output for the compact item `Use:` line, not the full Spell tooltip.
- Reuse Trait `BuildTooltipData().auraSections` for embedded Trait Aura detail on Item tooltips.
- Move skill-bonus lines below existing `Equip:` stat lines.
- Extend Item dependency/pruning logic for cross-dataset `useSpellRef` references.

This keeps item use as a thin source/transaction layer around the existing Spell system and avoids a second execution, targeting, cooldown or tooltip-description architecture.