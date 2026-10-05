# Ghoul Ability Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for the Ghoul NPC abilities used by the Core Ghoul variants.

Import each **Aura** before its associated **Spell**. All entries target the Core dataset (`f82db71a`), use Main Action cooldown channel 1, are unlearnable by players, and are seeded for NPC authoring.

## Balance summary

- **Diseased Bite:** no cooldown; `85 + 0.2975 × MAP` Shadow damage plus a 20-turn -40% Strength/-40% Agility debuff.
- **Leap:** 4-turn cooldown; `123.25 + 0.431375 × MAP` Shadow damage plus a 1-turn Hammer-of-Justice-style stun.
- **Thrash:** no cooldown; `85 + 0.2975 × MAP` Physical damage plus a 3-turn bleed dealing `28.1667 + 0.15 × MAP` Physical damage per turn.

