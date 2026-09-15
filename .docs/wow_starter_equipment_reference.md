# WoW Starter Equipment Reference

This document collects three pieces of reference data for low-level equipment design:

1. the armour values of the three low-level grey armour families from **WoW Classic**, renamed to the proposed `Worn Linen ...`, `Worn Leather ...`, and `Worn Chainmail ...` naming scheme;
2. the **Retail WoW `startinggear` icon family** for cloth, leather, and mail/chain starter armour;
3. the minimum and maximum damage of **WoW Classic weapons usable at level 1**, together with their icon texture names.

> **Version note:** Armour and weapon statistics below are Classic-era values. Retail values for the same old item IDs are not interchangeable: Blizzard has rescaled many of them in modern WoW.

---

## 1. WoW Classic grey armour sets

### 1.1 Frayed cloth -> `Worn Linen ...`

| Slot | Original Classic item | Proposed name | Item ID | Item level | Armour |
|---|---|---|---:|---:|---:|
| Back | Frayed Cloak | **Worn Linen Cloak** | 1376 | 5 | 5 |
| Chest | Frayed Robe | **Worn Linen Robe** | 1380 | 4 | 8 |
| Wrist | Frayed Bracers | **Worn Linen Bracers** | 3365 | 5 | 4 |
| Hands | Frayed Gloves | **Worn Linen Gloves** | 1377 | 3 | 4 |
| Waist | Frayed Belt | **Worn Linen Belt** | 3363 | 3 | 3 |
| Legs | Frayed Pants | **Worn Linen Pants** | 1378 | 2 | 4 |
| Feet | Frayed Shoes | **Worn Linen Shoes** | 1374 | 4 | 5 |

**Full 7-piece armour total: 33.**

> Some old Wowhead comments quote a total of 29 armour for the Frayed set because they omit the 4-armour Frayed Pants. The seven individual Classic item values above total **33**.

Classic sources:
- https://www.wowhead.com/classic/item=1376/frayed-cloak
- https://www.wowhead.com/classic/item=1380/frayed-robe
- https://www.wowhead.com/classic/item=3365/frayed-bracers
- https://www.wowhead.com/classic/item=1377/frayed-gloves
- https://www.wowhead.com/classic/item=3363/frayed-belt
- https://www.wowhead.com/classic/item=1378/frayed-pants
- https://www.wowhead.com/classic/item=1374/frayed-shoes

---

### 1.2 Ragged Leather -> `Worn Leather ...`

| Slot | Original Classic item | Proposed name | Item ID | Item level | Armour |
|---|---|---|---:|---:|---:|
| Back | Ragged Cloak | **Worn Leather Cloak** | 1372 | 3 | 3 |
| Chest | Ragged Leather Vest | **Worn Leather Vest** | 1364 | 5 | 31 |
| Wrist | Ragged Leather Bracers | **Worn Leather Bracers** | 1370 | 4 | 12 |
| Hands | Ragged Leather Gloves | **Worn Leather Gloves** | 1368 | 4 | 17 |
| Waist | Ragged Leather Belt | **Worn Leather Belt** | 1369 | 5 | 18 |
| Legs | Ragged Leather Pants | **Worn Leather Pants** | 1366 | 2 | 17 |
| Feet | Ragged Leather Boots | **Worn Leather Boots** | 1367 | 3 | 16 |

**Full 7-piece armour total: 114.**

Classic sources:
- https://www.wowhead.com/classic/item=1372/ragged-cloak
- https://www.wowhead.com/classic/item=1364/ragged-leather-vest
- https://www.wowhead.com/classic/item=1370/ragged-leather-bracers
- https://www.wowhead.com/classic/item=1368/ragged-leather-gloves
- https://www.wowhead.com/classic/item=1369/ragged-leather-belt
- https://www.wowhead.com/classic/item=1366/ragged-leather-pants
- https://www.wowhead.com/classic/item=1367/ragged-leather-boots

---

### 1.3 Flimsy Chain -> `Worn Chainmail ...`

Classic's armour subclass calls these items **Mail**. `Chainmail` is used below as the requested RPE-facing name.

| Slot | Original Classic item | Proposed name | Item ID | Item level | Armour |
|---|---|---|---:|---:|---:|
| Back | Flimsy Chain Cloak | **Worn Chainmail Cloak** | 2652 | 5 | 5 |
| Chest | Flimsy Chain Vest | **Worn Chainmail Vest** | 2656 | 5 | 63 |
| Wrist | Flimsy Chain Bracers | **Worn Chainmail Bracers** | 2651 | 4 | 25 |
| Hands | Flimsy Chain Gloves | **Worn Chainmail Gloves** | 2653 | 4 | 35 |
| Waist | Flimsy Chain Belt | **Worn Chainmail Belt** | 2649 | 2 | 24 |
| Legs | Flimsy Chain Pants | **Worn Chainmail Pants** | 2654 | 2 | 37 |
| Feet | Flimsy Chain Boots | **Worn Chainmail Boots** | 2650 | 3 | 34 |

**Full 7-piece armour total: 223.**

Classic sources:
- https://www.wowhead.com/classic/item=2652/flimsy-chain-cloak
- https://www.wowhead.com/classic/item=2656/flimsy-chain-vest
- https://www.wowhead.com/classic/item=2651/flimsy-chain-bracers
- https://www.wowhead.com/classic/item=2653/flimsy-chain-gloves
- https://www.wowhead.com/classic/item=2649/flimsy-chain-belt
- https://www.wowhead.com/classic/item=2654/flimsy-chain-pants
- https://www.wowhead.com/classic/item=2650/flimsy-chain-boots

---

### 1.4 Low-level shield

A suitable shield in the same item-level band is **Bent Large Shield**.

| Original Classic item | Proposed name | Item ID | Item level | Armour | Block | Icon |
|---|---|---:|---:|---:|---:|---|
| Bent Large Shield | **Worn Shield** | 2211 | 4 | 32 | 1 | `INV_Shield_09` |

Suggested addon texture path:

```text
Interface\\Icons\\INV_Shield_09
```

Source: https://www.wowhead.com/classic/item=2211/bent-large-shield

---

## 2. Retail starter armour icons

Wowhead's Retail icon database contains a high-resolution starter armour family using the `startinggear` naming convention. The family was datamined for cloth, leather, mail and plate; for this reference only cloth, leather and mail are relevant.

Wowhead icon search supplied in the request:

https://www.wowhead.com/icons/name:start

Wowhead's write-up on the icon family:

https://www.wowhead.com/news/possible-new-starting-gear-armor-sets-found-in-patch-9-1-data-323955

### 2.1 Recommended mapping to the renamed starter armour

| Slot | `Worn Linen ...` icon | `Worn Leather ...` icon | `Worn Chainmail ...` icon |
|---|---|---|---|
| Chest | `INV_Cloth_StartingGear_A_01_CHEST` | `INV_Leather_StartingGear_A_01_CHEST` | `INV_Mail_StartingGear_A_01_CHEST` |
| Wrist | `INV_Cloth_StartingGear_A_01_BRACER` | `INV_Leather_StartingGear_A_01_BRACER` | `INV_Mail_StartingGear_A_01_BRACER` |
| Hands | `INV_Cloth_StartingGear_A_01_GLOVE` | `INV_Leather_StartingGear_A_01_GLOVE` | `INV_Mail_StartingGear_A_01_GLOVE` |
| Waist | `INV_Cloth_StartingGear_A_01_BELT` | `INV_Leather_StartingGear_A_01_BELT` | `INV_Mail_StartingGear_A_01_BELT` |
| Legs | `INV_Cloth_StartingGear_A_01_PANTS` | `INV_Leather_StartingGear_A_01_PANTS` | `INV_Mail_StartingGear_A_01_PANTS` |
| Feet | `INV_Cloth_StartingGear_A_01_BOOT` | `INV_Leather_StartingGear_A_01_BOOT` | `INV_Mail_StartingGear_A_01_BOOT` |

For addon data, prepend `Interface\\Icons\\`, for example:

```text
Interface\\Icons\\INV_Cloth_StartingGear_A_01_CHEST
Interface\\Icons\\INV_Leather_StartingGear_A_01_CHEST
Interface\\Icons\\INV_Mail_StartingGear_A_01_CHEST
```

### 2.2 Important naming detail

Retail uses **Mail** rather than `Chain`/`Chainmail` in these icon filenames. Therefore the correct icon family for the proposed `Worn Chainmail ...` items is:

```text
INV_Mail_StartingGear_A_01_...
```

not `INV_Chain_...`.

### 2.3 Cloaks

The `startinggear` armour family above provides the normal armour-piece icons (chest, wrists, hands, waist, legs and feet). A corresponding cloth/leather/mail `StartingGear_A_01` cloak icon is not part of the verified family used here. The three proposed cloaks should therefore use a separate generic cloak icon rather than fabricating a `startinggear` cloak filename.

Examples of Retail items which verify this icon family include:

- **Mage's Robes** -> `inv_cloth_startinggear_a_01_chest`
- **Mage's Mitts** -> `inv_cloth_startinggear_a_01_glove`
- **Priest's Sash** -> `inv_cloth_startinggear_a_01_belt`
- **Druid's Leggings** -> `inv_leather_startinggear_a_01_pants`
- the Wowhead icon entry `inv_leather_startinggear_a_01_bracer`

---

## 3. WoW Classic level-1 starter weapons

### Interpretation of "level 1"

In WoW Classic, the standard starter weapons listed below are **usable at character level 1 but are Item Level 2**. This section therefore uses **Required Level 1 / actual starter weapons**, rather than internal or unavailable database weapons that happen to have Item Level 1.

| Weapon | Item ID | Type | Item level | Required level | Min damage | Max damage | Speed | Icon texture |
|---|---:|---|---:|---:|---:|---:|---:|---|
| Worn Shortsword | 25 | Main Hand Sword | 2 | 1 | 1 | 3 | 1.90 | `INV_Sword_04` |
| Worn Mace | 36 | Main Hand Mace | 2 | 1 | 1 | 3 | 1.90 | `INV_Mace_03` |
| Worn Axe | 37 | Main Hand Axe | 2 | 1 | 1 | 3 | 2.00 | `INV_Axe_11` |
| Worn Dagger | 2092 | One-Hand Dagger | 2 | 1 | 1 | 2 | 1.60 | `INV_Weapon_ShortBlade_05` |
| Bent Staff | 35 | Two-Hand Staff | 2 | 1 | 3 | 5 | 2.90 | `INV_Staff_08` |
| Battleworn Hammer | 2361 | Two-Hand Mace | 2 | 1 | 3 | 5 | 2.90 | `INV_Hammer_16` |
| Worn Shortbow | 2504 | Ranged Bow | 2 | 1 | 2 | 5 | 2.30 | `INV_Weapon_Bow_05` |
| Old Blunderbuss | 2508 | Ranged Gun | 2 | 1 | 2 | 5 | 2.30 | `INV_Weapon_Rifle_01` |

### 3.1 Damage bands at level 1

For a compact baseline:

| Weapon group | Classic starter damage band |
|---|---:|
| One-hand sword / mace / axe | **1-3** |
| Dagger | **1-2** |
| Two-hand staff / mace | **3-5** |
| Bow / gun | **2-5** |

### 3.2 Addon icon paths

```text
Interface\\Icons\\INV_Sword_04
Interface\\Icons\\INV_Mace_03
Interface\\Icons\\INV_Axe_11
Interface\\Icons\\INV_Weapon_ShortBlade_05
Interface\\Icons\\INV_Staff_08
Interface\\Icons\\INV_Hammer_16
Interface\\Icons\\INV_Weapon_Bow_05
Interface\\Icons\\INV_Weapon_Rifle_01
```

Classic stat sources:
- https://www.wowhead.com/classic/item=25/worn-shortsword
- https://www.wowhead.com/classic/item=36/worn-mace
- https://www.wowhead.com/classic/item=37/worn-axe
- https://www.wowhead.com/classic/item=2092/worn-dagger
- https://www.wowhead.com/classic/item=35/bent-staff
- https://www.wowhead.com/classic/item=2361/battleworn-hammer
- https://www.wowhead.com/classic/item=2504/worn-shortbow
- https://www.wowhead.com/classic/item=2508/old-blunderbuss

Icon cross-checks were made against Wowhead icon pages/item relations and legacy database records where the texture name is exposed directly.

---

## 4. Compact RPE-facing reference

If the intent is to turn this directly into starter equipment definitions, the resulting naming/stats baseline is:

### Linen

```text
Worn Linen Cloak      5 armour
Worn Linen Robe       8 armour
Worn Linen Bracers    4 armour
Worn Linen Gloves     4 armour
Worn Linen Belt       3 armour
Worn Linen Pants      4 armour
Worn Linen Shoes      5 armour
```

### Leather

```text
Worn Leather Cloak     3 armour
Worn Leather Vest     31 armour
Worn Leather Bracers  12 armour
Worn Leather Gloves   17 armour
Worn Leather Belt     18 armour
Worn Leather Pants    17 armour
Worn Leather Boots    16 armour
```

### Chainmail

```text
Worn Chainmail Cloak      5 armour
Worn Chainmail Vest      63 armour
Worn Chainmail Bracers   25 armour
Worn Chainmail Gloves    35 armour
Worn Chainmail Belt      24 armour
Worn Chainmail Pants     37 armour
Worn Chainmail Boots     34 armour
```

### Shield

```text
Worn Shield              32 armour, 1 block
```

### Starter weapon damage

```text
Sword       1-3
Mace        1-3
Axe         1-3
Dagger      1-2
Staff       3-5
2H Mace     3-5
Bow         2-5
Gun         2-5
```
