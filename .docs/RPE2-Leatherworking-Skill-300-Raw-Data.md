# Leatherworking Skill 300 — Raw Source Data

## Scope

Raw source-side records for Leatherworking recipes requiring **exactly 300 skill**, retained for implementation into the RPE2 default Leatherworking dataset.

Primary requested source: `https://wow.playjournals.com/tbc/en/professions/leatherworking/all`

The records below were cross-checked against the TBC Leatherworking profession data in TimbersFieldGuide at commit `b082a32fdeda215d7894e02aa1691a97dc92f030`.

This file deliberately preserves source IDs and quantities. It does **not** apply RPE2 reagent normalization, item-level conversion, stat conversion, dataset references, or generated RPE IDs.

### Current filtering rules

- Leatherworking skill requirement must be exactly `300`.
- Do not include any recipe requiring Knothide Leather or Knothide Leather Scraps.
- Quivers and ammo pouches are excluded.
- Final implementation is restricted to uncommon, rare and epic outputs.
- Item level conversion is handled during implementation, not in this raw-data file.

### Explicit Knothide exclusions

The following skill-300 records are not part of the candidate set because they are Knothide products or require Knothide Leather:

- Knothide Leather — spell `32454`, product `21887`
- Knothide Armor Kit — spell `32456`, product `25650`
- Felscale Gloves — spell `32462`, product `25654`
- Scaled Draenic Pants — spell `32466`, product `25662`
- Thick Draenic Gloves — spell `32470`, product `25669`
- Wild Draenish Boots — spell `32478`, product `25673`
- Comfortable Insoles — spell `32482`, product `25679`
- Leatherworker's Satchel — spell `45100`, product `34482`

## Raw records

`levels` is the profession difficulty tuple from the source data. For these records it is normally `{ orange, yellow, green, gray } = { 300, 320, 330, 340 }`.

| Spell ID | Name | Icon | Recipe source | Product item ID | Raw materials | Levels |
|---:|---|---|---|---:|---|---|
| 19054 | Red Dragonscale Breastplate | `inv_chest_chain_06` | Item `15730` | 15047 | `8170 x40; 15414 x30; 14341 x1` | `300,320,330,340` |
| 19091 | Runic Leather Pants | `inv_pants_02` | Item `15765`, cost 15000 | 15095 | `8170 x18; 14047 x12; 12810 x2; 14341 x1` | `300,320,330,340` |
| 19092 | Wicked Leather Belt | `inv_belt_03` | Item `15768`, cost 15000 | 15088 | `8170 x14; 2325 x2; 14341 x2` | `300,320,330,340` |
| 19093 | Onyxia Scale Cloak | `inv_misc_cape_05` | Item `15769` | 15138 | `15410 x1; 14044 x1; 14341 x1` | `300,320,330,340` |
| 19094 | Black Dragonscale Shoulders | `inv_shoulder_01` | Item `15770` | 15051 | `8170 x44; 15416 x45; 12810 x2; 15407 x1; 14341 x1` | `300,320,330,340` |
| 19095 | Living Breastplate | `inv_chest_plate07` | Item `15771` | 15059 | `8170 x16; 12803 x8; 14342 x2; 15407 x1; 14341 x2` | `300,320,330,340` |
| 19097 | Devilsaur Leggings | `inv_pants_wolf` | Item `15772` | 15062 | `8170 x30; 15417 x14; 15407 x1; 14341 x1` | `300,320,330,340` |
| 19098 | Wicked Leather Armor | `inv_chest_plate06` | Item `15773`, cost 15000 | 15085 | `8170 x20; 15407 x2; 14256 x2; 2325 x4; 14341 x2` | `300,320,330,340` |
| 19100 | Heavy Scorpid Shoulders | `inv_shoulder_07` | Item `15774` | 15081 | `8170 x14; 15408 x14; 15407 x1; 14341 x2` | `300,320,330,340` |
| 19101 | Volcanic Shoulders | `inv_shoulder_13` | Item `15775` | 15055 | `8170 x10; 7078 x1; 7076 x1; 14341 x2` | `300,320,330,340` |
| 19102 | Runic Leather Armor | `inv_chest_leather_07` | Item `15776`, cost 15000 | 15090 | `8170 x22; 12810 x4; 14047 x16; 15407 x1; 14341 x2` | `300,320,330,340` |
| 19103 | Runic Leather Shoulders | `inv_shoulder_15` | Item `15777`, cost 15000 | 15096 | `8170 x16; 12810 x4; 14047 x18; 15407 x1; 14341 x2` | `300,320,330,340` |
| 19104 | Frostsaber Tunic | `inv_chest_chain_10` | Item `15779` | 15068 | `8170 x12; 15422 x12; 15407 x1; 14341 x2` | `300,320,330,340` |
| 19107 | Black Dragonscale Leggings | `inv_pants_03` | Item `15781` | 15052 | `8170 x40; 15416 x60; 12810 x4; 15407 x1; 14341 x2` | `300,320,330,340` |
| 20854 | Molten Helm | `inv_helmet_08` | Item `17023` | 16983 | `17012 x15; 17010 x3; 17011 x6; 14341 x2` | `300,320,330,340` |
| 20855 | Black Dragonscale Boots | `inv_boots_plate_09` | Item `17025` | 16984 | `12810 x6; 15416 x30; 17010 x4; 17011 x3; 14341 x2` | `300,320,330,340` |
| 22727 | Core Armor Kit | `inv_misc_armorkit_05` | Item `18252` | 18251 | `17012 x3; 14341 x2` | `300,320,330,340` |
| 22921 | Girdle of Insight | `inv_belt_26` | Item `18514` | 18504 | `8170 x12; 12804 x12; 15407 x2; 14341 x4` | `300,320,330,340` |
| 22922 | Mongoose Boots | `inv_boots_08` | Item `18515` | 18506 | `8170 x12; 7082 x6; 11754 x4; 15407 x2; 14341 x4` | `300,320,330,340` |
| 22923 | Swift Flight Bracers | `inv_bracer_05` | Item `18516` | 18508 | `8170 x12; 18512 x8; 15420 x60; 15407 x4; 14341 x4` | `300,320,330,340` |
| 22926 | Chromatic Cloak | `inv_misc_cape_02` | Item `18517` | 18509 | `8170 x30; 12607 x12; 15416 x30; 15414 x30; 15407 x5; 14341 x8` | `300,320,330,340` |
| 22927 | Hide of the Wild | `inv_misc_cape_01` | Item `18518` | 18510 | `8170 x30; 12803 x12; 7080 x10; 18512 x8; 15407 x3; 14341 x8` | `300,320,330,340` |
| 22928 | Shifting Cloak | `inv_misc_cape_20` | Item `18519` | 18511 | `8170 x30; 7082 x12; 12753 x4; 12809 x8; 15407 x4; 14341 x8` | `300,320,330,340` |
| 23704 | Timbermaw Brawlers | `inv_gauntlets_26` | Item `19327` | 19049 | `12810 x8; 12804 x6; 12803 x6; 15407 x2; 14227 x2` | `300,320,330,340` |
| 23706 | Golden Mantle of the Dawn | `inv_shoulder_26` | Item `19329` | 19058 | `12810 x8; 12803 x4; 12809 x4; 15407 x2; 14341 x2` | `300,320,330,340` |
| 23707 | Lava Belt | `inv_belt_32` | Item `19330` | 19149 | `17011 x5; 15407 x4; 14227 x4` | `300,320,330,340` |
| 23708 | Chromatic Gauntlets | `inv_gauntlets_22` | Item `19331` | 19157 | `17010 x5; 17011 x2; 17012 x4; 12607 x4; 15407 x4; 14227 x4` | `300,320,330,340` |
| 23709 | Corehound Belt | `inv_belt_24` | Item `19332` | 19162 | `17010 x8; 17012 x12; 12810 x10; 15407 x4; 14227 x4` | `300,320,330,340` |
| 23710 | Molten Belt | `inv_belt_13` | Item `19333` | 19163 | `17010 x2; 17011 x7; 7076 x6; 15407 x4; 14227 x4` | `300,320,330,340` |
| 24121 | Primal Batskin Jerkin | `inv_chest_leather_03` | Item `19769` | 19685 | `19767 x14; 15407 x5; 12803 x4; 14341 x4` | `300,320,330,340` |
| 24122 | Primal Batskin Gloves | `inv_gauntlets_31` | Item `19770` | 19686 | `19767 x10; 15407 x4; 12803 x4; 14341 x3` | `300,320,330,340` |
| 24123 | Primal Batskin Bracers | `inv_bracer_07` | Item `19771` | 19687 | `19767 x8; 15407 x3; 12803 x4; 14341 x3` | `300,320,330,340` |
| 24124 | Blood Tiger Breastplate | `inv_chest_leather_07` | Item `19772` | 19688 | `19768 x35; 19726 x2; 15407 x3; 14341 x3` | `300,320,330,340` |
| 24125 | Blood Tiger Shoulders | `inv_shoulder_23` | Item `19773` | 19689 | `19768 x25; 19726 x2; 15407 x3; 14341 x3` | `300,320,330,340` |
| 24654 | Blue Dragonscale Leggings | `inv_pants_mail_15` | Trainer, cost 50000 | 20295 | `8170 x28; 15415 x36; 15407 x2; 14341 x2` | `300,320,330,340` |
| 24703 | Dreamscale Breastplate | `inv_chest_plate08` | Item `20382` | 20380 | `12810 x12; 20381 x6; 12803 x4; 15407 x4; 14227 x6` | `300,320,330,340` |
| 24846 | Spitfire Bracers | `inv_bracer_05` | Item `20506` | 20481 | `20500 x1; 20498 x20; 7078 x2` | `300,320,330,340` |
| 24847 | Spitfire Gauntlets | `inv_gauntlets_11` | Item `20507` | 20480 | `20500 x2; 20498 x30; 7078 x2; 15407 x1` | `300,320,330,340` |
| 24848 | Spitfire Breastplate | `inv_chest_leather_02` | Item `20508` | 20479 | `20500 x3; 20498 x40; 7078 x2; 15407 x2` | `300,320,330,340` |
| 24849 | Sandstalker Bracers | `inv_bracer_12` | Item `20509` | 20476 | `20501 x1; 20498 x20; 18512 x2` | `300,320,330,340` |
| 24850 | Sandstalker Gauntlets | `inv_gauntlets_11` | Item `20510` | 20477 | `20501 x2; 20498 x30; 18512 x2; 15407 x1` | `300,320,330,340` |
| 24851 | Sandstalker Breastplate | `inv_chest_plate07` | Item `20511` | 20478 | `20501 x3; 20498 x40; 18512 x2; 15407 x2` | `300,320,330,340` |
| 26279 | Stormshroud Gloves | `inv_gauntlets_05` | Item `21548` | 21278 | `12810 x6; 7080 x4; 7082 x4; 15407 x2; 14227 x2` | `300,320,330,340` |
| 28219 | Polar Tunic | `inv_chest_cloth_08` | Item `22692` | 22661 | `22682 x7; 12810 x16; 7080 x2; 15407 x4; 14227 x4` | `300,320,330,340` |
| 28220 | Polar Gloves | `inv_gauntlets_06` | Item `22694` | 22662 | `22682 x5; 12810 x12; 7080 x2; 15407 x3; 14227 x4` | `300,320,330,340` |
| 28221 | Polar Bracers | `inv_bracer_07` | Item `22695` | 22663 | `22682 x4; 12810 x12; 7080 x2; 15407 x2; 14227 x4` | `300,320,330,340` |
| 28222 | Icy Scale Breastplate | `inv_chest_plate09` | Item `22696` | 22664 | `22682 x7; 15408 x24; 7080 x2; 15407 x4; 14227 x4` | `300,320,330,340` |
| 28223 | Icy Scale Gauntlets | `inv_gauntlets_28` | Item `22697` | 22666 | `22682 x5; 15408 x16; 7080 x2; 15407 x3; 14227 x4` | `300,320,330,340` |
| 28224 | Icy Scale Bracers | `inv_bracer_07` | Item `22698` | 22665 | `22682 x4; 15408 x16; 7080 x2; 15407 x2; 14227 x4` | `300,320,330,340` |
| 28472 | Bramblewood Helm | `inv_helmet_58` | Item `22771` | 22759 | `12810 x12; 19726 x2; 12803 x2; 15407 x2` | `300,320,330,340` |
| 28473 | Bramblewood Boots | `inv_boots_cloth_04` | Item `22770` | 22760 | `12810 x6; 18512 x2; 12803 x2; 15407 x2` | `300,320,330,340` |
| 28474 | Bramblewood Belt | `inv_belt_17` | Item `22769` | 22761 | `12810 x4; 12803 x2; 15407 x1` | `300,320,330,340` |

## Raw material ID reference

These are names represented by the item IDs above. This section is only a convenience index; quantities in the table remain the authoritative raw values.

| Item ID | Name |
|---:|---|
| 2325 | Black Dye |
| 7076 | Essence of Earth |
| 7078 | Essence of Fire |
| 7080 | Essence of Water |
| 7082 | Essence of Air |
| 8170 | Rugged Leather |
| 11754 | Black Diamond |
| 12607 | Brilliant Chromatic Scale |
| 12753 | Skin of Shadow |
| 12803 | Living Essence |
| 12804 | Powerful Mojo |
| 12809 | Guardian Stone |
| 12810 | Enchanted Leather |
| 14044 | Cindercloth Cloak |
| 14047 | Runecloth |
| 14227 | Ironweb Spider Silk |
| 14256 | Felcloth |
| 14341 | Rune Thread |
| 14342 | Mooncloth |
| 15407 | Cured Rugged Hide |
| 15408 | Heavy Scorpid Scale |
| 15410 | Scale of Onyxia |
| 15414 | Red Dragonscale |
| 15415 | Blue Dragonscale |
| 15416 | Black Dragonscale |
| 15417 | Devilsaur Leather |
| 15420 | Ironfeather |
| 15422 | Frostsaber Leather |
| 17010 | Fiery Core |
| 17011 | Lava Core |
| 17012 | Core Leather |
| 18512 | Larval Acid |
| 19726 | Bloodvine |
| 19767 | Primal Bat Leather |
| 19768 | Primal Tiger Leather |
| 20381 | Dreamscale |
| 20498 | Silithid Chitin |
| 20500 | Light Silithid Carapace |
| 20501 | Heavy Silithid Carapace |
| 22682 | Frozen Rune |

## RPE2 conversion rules to apply later

These are implementation rules from the task and are intentionally **not applied** to the raw records above:

- Item level = required level + 5.
- Rare item level maximum = 55.
- Epic item level maximum = 60.
- Hides and scales are treated as leather; e.g. one Cured Heavy Hide becomes four Heavy Leather.
- Belt buckles are replaced by the corresponding metal bar from the Blacksmithing dataset.
- Gems and pearls use the Jewelcrafting dataset.
- Miscellaneous materials use the Misc dataset.
- Stats and item-slot references use the Core dataset.
