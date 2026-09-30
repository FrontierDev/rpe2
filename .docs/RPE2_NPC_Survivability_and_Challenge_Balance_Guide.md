# RPE2 NPC Survivability & Challenge-Level Balance Guide

**Status:** Provisional Level-60 calibration  
**Purpose:** provide a repeatable basis for authoring and simulating NPC Health, Armor, MAP, RAP, Spell Power, Healing Power, and encounter pressure for `swarm`, `minor`, `normal`, `elite`, and `boss` challenge levels.

This document complements the 5-player/10-player combat simulation guide. It should be recalculated whenever player gear, spell coefficients, mitigation rules, NPC difficulty modifiers, or core NPC equipment changes.

---

# 1. Core principle

NPC challenge level should describe **encounter pressure**, not merely durability.

The intended progression is:

- **Swarm:** individually weak; dangerous through numbers.
- **Minor:** low-pressure supporting enemy.
- **Normal:** ordinary combatant; one or two straightforward attacks.
- **Elite:** sustained threat with DoTs, debuffs, control, or other detrimental mechanics.
- **Boss:** sustained danger to the tank plus periodic raid/tank mechanics.
- **Tankbuster:** not a separate challenge level; a temporary Boss/Elite attack budget above normal sustained pressure.

Challenge level should not be used as a substitute for:

- class/role preset;
- gear tier;
- encounter difficulty;
- player count;
- special mechanics.

---

# 2. Current runtime difficulty modifiers

Current event difficulty modifiers are:

| Difficulty | NPC Health | NPC direct damage | Hit | Defence |
|---|---:|---:|---:|---:|
| Normal | ×1.00 | ×1.00 | +0 | +0 |
| Heroic | ×1.10 | ×1.10 | +0 | +0 |
| Mythic | ×1.25 | ×1.25 | +3 | +3 |

Current challenge-template Damage Done values are:

| Challenge | Damage Done |
|---|---:|
| Swarm | -50% |
| Minor | -25% |
| Normal | 0% |
| Elite | +10% |
| Boss | +20% |

For direct damage, the combined multiplier is therefore:

| Challenge | Normal | Heroic | Mythic |
|---|---:|---:|---:|
| Swarm | 0.50× | 0.55× | 0.625× |
| Minor | 0.75× | 0.825× | 0.9375× |
| Normal | 1.00× | 1.10× | 1.25× |
| Elite | 1.10× | 1.21× | 1.375× |
| Boss | 1.20× | 1.32× | 1.50× |

The authored Normal-difficulty stat range must therefore be safe at its Mythic upper end.

---

# 3. Reference player survivability

## 3.1 Level-60 T0.5 reference tank

Protection Warrior reference:

- Health: approximately **4,598**
- Armor: approximately **4,087**
- Defensive Stance: **+10% Damage Reduction**
- Defensive Stance: **+80% Threat Generated**

Under the intended percentage Armor model:

```text
Physical Armor mitigation
= Armor / 10000 × 40%
≈ 16.35%
```

After Defensive Stance:

```text
Physical damage multiplier
≈ (1 - 0.1635) × (1 - 0.10)
≈ 0.753
```

So the T0.5 tank takes roughly **75% of pre-mitigation Physical damage** before block/avoidance.

## 3.2 Level-60 T2 reference tank

Approximate reference:

- Health: approximately **4,918**
- Armor: approximately **4,925**
- Defensive Stance: **10% Damage Reduction**

Under the same model:

```text
Armor mitigation ≈ 19.7%
Final Physical multiplier ≈ 0.723
```

This gives only a modest increase in survivability relative to T0.5, which is desirable for challenge-level authoring.

---

# 4. Reference healer throughput

Use a Level-60 Priest as the primary five-player healer calibration.

## 4.1 T0.5 — approximately 300 Healing Power

Expected non-critical output:

| Spell | Approximate output |
|---|---:|
| Heal | 500 |
| Renew | 270 / turn |
| Heal + maintained Renew | **770 / turn** |
| Power Word: Shield | 379 absorption |
| Greater Heal | 1,126 |
| Prayer of Mending | 2% Max HP per triggered stack |

Therefore:

- approximately **770/turn** is a useful sustained single-target healing reference;
- approximately **1,100–1,500** recovery in a turn is possible through emergency healing/shield combinations;
- repeated damage substantially above ~770/turn should gradually consume emergency tools or additional healer resources.

## 4.2 T2 — approximately 429 Healing Power

Expected non-critical output:

| Spell | Approximate output |
|---|---:|
| Heal | 635 |
| Renew | 375 / turn |
| Heal + maintained Renew | **1,010 / turn** |
| Power Word: Shield | 483 absorption |
| Greater Heal | 1,428 |

This should be treated as the upper end of the normal Level-60 reference band.

---

# 5. Target incoming-damage bands

The primary survivability calibration is the percentage of tank HP lost per enemy turn.

## 5.1 T0.5 target pressure

| Challenge | Intended sustained pressure | T0.5 tank HP / turn |
|---|---:|---:|
| Swarm | 2–4% | 92–184 |
| Minor | 4–8% | 184–368 |
| Normal | 8–14% | **368–644** |
| Elite | 15–25% | **690–1,150** |
| Boss | 20–30% | **920–1,379** |
| Tankbuster | 30–45% | **1,379–2,069** |

## 5.2 T2 target pressure

| Challenge | T2 tank HP / turn |
|---|---:|
| Swarm | 98–197 |
| Minor | 197–393 |
| Normal | **393–689** |
| Elite | **738–1,230** |
| Boss | **984–1,475** |
| Tankbuster | **1,475–2,213** |

These are **total encounter-pressure budgets**, not necessarily direct-attack budgets.

For Elite/Boss NPCs:

```text
Total pressure
= direct damage
+ periodic damage
+ mechanic pressure
```

Do not give an Elite/Boss full-band direct damage and then add unrestricted DoTs/control on top.

---

# 6. Level-60 offensive stat bands

These ranges are intended as **resolved post-preset values**.

If a role preset adds `+20% MAP`, for example, the underlying Unit value should be low enough that the resolved final MAP remains in the intended band.

## 6.1 Martial/ranged NPCs

The current Core Human NPC presets use level-2 Worn weapons, whose weapon damage is extremely small. The ranges below are calibrated around those current weapons, with offensive scaling coming primarily from MAP/RAP.

| Challenge | MAP / RAP target |
|---|---:|
| Swarm | **100–250** |
| Minor | **200–350** |
| Normal | **350–650** |
| Elite | **500–850** |
| Boss | **650–1,000** |

Do not automatically increase Boss MAP above this range to create tankbusters. Use a stronger attack coefficient/cooldown mechanic instead.

## 6.2 Expected direct physical pressure

Using:

- current low-damage Human NPC weapons;
- one basic attack plus one standard ranked weapon action;
- current challenge crit assumptions;
- current challenge Damage Done;
- T0.5 tank Physical mitigation;

the resolved direct pressure is approximately:

| Challenge | Normal | Heroic | Mythic |
|---|---:|---:|---:|
| Normal, 350–650 AP | **355–585** | **390–644** | **443–732** |
| Elite, 500–850 AP | **527–828** | **580–911** | **659–1,036** |
| Boss, 650–1,000 AP | **736–1,074** | **809–1,181** | **920–1,343** |

Interpretation:

- Normal pressure can be almost entirely direct.
- Elite direct pressure should leave room for approximately 150–300 damage/turn of DoT/mechanic pressure.
- Boss direct pressure should leave room for periodic/raid/tank mechanics.
- Mythic Boss upper-end direct damage is already close to the sustainable-healing limit before mechanics.

## 6.3 Weapon substitution rule

If stronger NPC weapons are introduced, reduce AP/RAP rather than simply adding weapon damage on top.

For a two-hit package:

```text
Raw damage
≈ 101.25
+ 2.35 × average weapon damage
+ 0.9725 × AP
```

Therefore approximately:

```text
+1 average weapon damage
≈ +2.42 AP-equivalent
```

To preserve output:

```text
new AP
≈ old AP - 2.42 × increase in average weapon damage
```

This means replacing a 3-damage Worn weapon with a 100-damage weapon is worth roughly **235 AP** in the standard two-hit model.

---

# 7. Spell Power bands

Spell Power must be separated into two archetypes because the periodic coefficient model is very strong.

## 7.1 Direct-damage-only caster

| Challenge | Spell Power |
|---|---:|
| Swarm | 80–150 |
| Minor | 100–180 |
| Normal | **150–300** |
| Elite | **350–550** |
| Boss | **400–550** |

Use this band when the caster's sustained turn is predominantly one direct damaging spell and it does not maintain a significant SP-scaled DoT.

## 7.2 DoT-heavy caster

| Challenge | Spell Power |
|---|---:|
| Normal | Avoid persistent high-coefficient DoTs by default |
| Elite | **180–300** |
| Boss | **220–350** |

A DoT-heavy caster needs substantially less SP because RPE periodic damage applies the full stat coefficient every tick.

## 7.3 Current-runtime caster pressure

Using a Fireball-like direct spell:

| Challenge | Normal | Heroic | Mythic |
|---|---:|---:|---:|
| Normal direct-only, 150–300 SP | **393–632** | **432–695** | **491–790** |
| Elite direct + DoT, 180–300 SP | **733–1,090** | **782–1,161** | **856–1,267** |
| Boss direct + DoT, 220–350 SP | **921–1,336** | **984–1,426** | **1,079–1,560** |

The Elite/Boss upper ends are deliberately dangerous.

Do not add another full-strength DoT or repeated free proc without reducing SP or direct damage.

---

# 8. Current periodic-damage runtime caveat

Current top-level Aura damage does **not** use the normal direct-damage resolution path.

It currently applies the resolved aura amount directly to the target Health resource.

As a result, current periodic Aura damage does not consistently receive:

- Armor;
- school resistance mitigation;
- target Damage Reduction;
- attacker Damage Done;
- Heroic/Mythic NPC damage bonus.

This is a major survivability-calibration distinction.

Therefore:

1. current-runtime simulations must model DoT ticks as direct resource loss;
2. direct-damage Heroic/Mythic multipliers must not be silently applied to current DoT ticks;
3. if periodic damage is later routed through normal damage resolution, all Elite/Boss DoT-heavy ranges must be re-simulated.

The SP bands in this document reflect the **current runtime behavior**.

---

# 9. Healing Power bands for NPC healers

Healing Power should also be challenge-banded.

Recommended resolved Level-60 ranges:

| Challenge | Healing Power |
|---|---:|
| Swarm | 0–100 |
| Minor | 100–200 |
| Normal | **200–350** |
| Elite | **300–500** |
| Boss/support boss | **400–700** |

Using the current Priest Heal/Renew/Shield formulas:

| Challenge | Heal | Renew / turn | Shield |
|---|---:|---:|---:|
| Minor, 100–200 HPow | 292–396 | 108–189 | 216–297 |
| Normal, 200–350 HPow | **396–552** | **189–311** | **297–419** |
| Elite, 300–500 HPow | **500–708** | **270–433** | **379–541** |
| Boss, 400–700 HPow | **604–916** | **352–595** | **460–703** |

An NPC healer should not be given this entire output continuously if doing so causes enemy healing to exceed player damage against the encounter.

Treat healing as part of the encounter durability budget.

---

# 10. Armor bands

The following Armor values assume the intended Level-60 percentage mitigation model:

```text
10000 Armor = 40% Physical mitigation
```

Recommended resolved Level-60 Armor:

| Challenge | Armor | Approx. Physical mitigation |
|---|---:|---:|
| Swarm | 0–500 | 0–2% |
| Minor | 500–1,200 | 2–4.8% |
| Normal | **1,500–3,000** | **6–12%** |
| Elite | **3,000–5,000** | **12–20%** |
| Boss | **4,000–7,000** | **16–28%** |

Do not give every NPC broad elemental resistance by default.

School resistances should be identity/mechanic-specific.

---

# 11. Mitigation-model requirement

The Core rules definition currently has `damage_school_mitigation_model = legacy` as its fallback/default.

That model is incompatible with the current endgame Armor scale if used literally:

```text
legacy Physical mitigation
= Armor × 0.1%
```

Thousands of Armor would immediately cap near 100%.

The survivability numbers in this document therefore assume the **percentage reference model** (`fixed_percent` or `level_scaled_percent`) using the Core reference values.

Before using these tables as production balance authority, verify that the active default ruleset explicitly uses the intended percentage mitigation model.

If it does not, that must be corrected before meaningful survivability calibration is possible.

---

# 12. Level-60 Health bands

Health is more encounter-size-sensitive than offensive stats.

The following values are **authored pre-player-scaling Normal-difficulty Health at Level 60**.

| Challenge | Authored L60 Health |
|---|---:|
| Swarm | **800–1,500** |
| Minor | **1,000–2,000** |
| Normal | **2,300–4,000** |
| Elite | **8,000–15,000** |
| Boss — 5-player target | **75,000–90,000** |

The current player-count system scales Minor/Normal/Elite by:

```text
1 + playerCount × 10%
```

Therefore at five players:

| Challenge | 5-player Normal runtime HP |
|---|---:|
| Swarm | 800–1,500 |
| Minor | **1,500–3,000** |
| Normal | **3,450–6,000** |
| Elite | **12,000–22,500** |
| Boss | **75,000–90,000** |

Difficulty then produces:

| Challenge | Normal | Heroic | Mythic |
|---|---:|---:|---:|
| Swarm | 0.8–1.5k | 0.88–1.65k | 1.0–1.875k |
| Minor | 1.5–3.0k | 1.65–3.3k | 1.875–3.75k |
| Normal | 3.45–6.0k | 3.80–6.6k | 4.31–7.5k |
| Elite | 12–22.5k | 13.2–24.75k | 15–28.13k |
| Boss | **75–90k** | **82.5–99k** | **93.75–112.5k** |

---

# 13. Expected five-player time-to-kill

The current five-player T0.5 reference party produces approximately **8.2k raw damage/turn** after correcting Warrior tank output.

Once reasonable NPC Armor is included, effective party damage is lower, but only the Physical fraction of party damage is affected. The Boss HP band is therefore chosen so that **Normal usually lands near the lower-middle of the 10–15-turn window**, while Heroic/Mythic Health bonuses extend the fight toward the upper end rather than beyond it.

Approximate intended focused-target behavior:

| Challenge | Expected focused lifetime |
|---|---|
| Swarm | generally killed by one strong player action |
| Minor | substantially less than one full party turn |
| Normal | approximately half to one full party turn |
| Elite | approximately 1.5–3 party turns |
| Boss | approximately **10–15 turns** |

This is why a Boss HP value around 6–10k is not viable for current endgame player output.

---

# 14. Ten-player scaling

A ten-player reference group contains approximately twice the role count of a five-player group:

- 2 tanks;
- 2 healers;
- 6 DPS.

Its raw throughput should therefore be expected to approach roughly **2×** the five-player reference unless the specific roster says otherwise.

## 14.1 Ordinary enemies

Do **not** double MAP/RAP/SP for ten-player content.

Ordinary enemy danger to one player should remain similar.

Scale ten-player encounters primarily through:

- more enemies;
- more simultaneous targets;
- more DoTs/debuffs;
- more raid damage;
- multi-tank mechanics;
- encounter complexity.

Per-unit Normal/Elite HP may rise somewhat, but encounter count should do most of the scaling.

## 14.2 Boss Health

Boss Health is different because a single raid boss receives the throughput of the entire raid.

To preserve roughly the same TTK:

```text
10-player Boss HP
≈ 2 × 5-player Boss HP
```

Recommended Normal-difficulty Level-60 target:

| Group | Boss runtime HP |
|---|---:|
| 5-player | **75–90k** |
| 10-player | **150–180k** |

Heroic and Mythic then apply their normal health bonuses.

---

# 15. Current player-count scaling problem

Current automatic per-player Health scaling applies by default to:

- Minor;
- Normal;
- Elite.

It does **not** apply to:

- Swarm;
- Boss.

For scalable tiers:

```text
5 players -> ×1.5 HP
10 players -> ×2.0 HP
```

So moving from five to ten players only increases HP by:

```text
2.0 / 1.5 = 1.333×
```

while reference party throughput approaches roughly **2×**.

Bosses receive **no automatic player-count increase at all**.

Therefore the current player-count Health scaling cannot preserve time-to-kill between five-player and ten-player encounters.

Until that system is revised:

- use the five-player Boss range for five-player content;
- use an explicitly larger Boss value/preset for ten-player content;
- use additional enemy count for ordinary ten-player encounters;
- do not assume the current automatic Health scaling provides raid-size parity.

---

# 16. Challenge-level authoring summary

These are the recommended resolved Level-60 ranges.

| Challenge | Health* | Armor | MAP/RAP | SP direct-only | SP DoT-heavy | Healing Power |
|---|---:|---:|---:|---:|---:|---:|
| Swarm | 0.8–1.5k | 0–500 | 100–250 | 80–150 | — | 0–100 |
| Minor | 1.5–3.0k | 500–1,200 | 200–350 | 100–180 | — | 100–200 |
| Normal | 3.45–6.0k | 1,500–3,000 | **350–650** | **150–300** | avoid by default | **200–350** |
| Elite | 12–22.5k | 3,000–5,000 | **500–850** | **350–550** | **180–300** | **300–500** |
| Boss, 5p | **75–90k** | **4,000–7,000** | **650–1,000** | **400–550** | **220–350** | **400–700** |
| Boss, 10p | **150–180k** | **4,000–7,000** | **650–1,000** | **400–550** | **220–350** | **400–700** |

\* Health shown here is the intended five-player **runtime** Normal-difficulty result. Minor/Normal/Elite authored base Health must account for the current +10% per-player system.

The offensive stat bands do **not** change for ten players.

---

# 17. Role preset interaction

Challenge stats and role presets are separate layers.

The target table above describes the **resolved combatant**.

Examples:

If a Normal Archer should resolve to 600 RAP and the Archer preset adds +20% RAP:

```text
base RAP
= 600 / 1.20
= 500
```

If a Boss Mage should resolve to 300 SP and the Mage preset adds +25% SP:

```text
base SP
= 300 / 1.25
= 240
```

Do not author a Unit at the top of the challenge band and then apply an offensive role preset without checking the resolved value.

Likewise Damage Done from presets stacks with challenge Damage Done and event difficulty.

---

# 18. Designing Elite mechanics

An Elite should generally have:

- one reliable direct action;
- one basic/bonus action or equivalent;
- one persistent detrimental mechanic.

Examples:

- DoT;
- healing reduction;
- Armor reduction;
- silence;
- control;
- stacking vulnerability;
- forced target switching.

Recommended pressure split:

```text
60–80% direct damage
20–40% periodic/mechanic pressure
```

A stun/silence/healing reduction has no direct numerical damage but consumes part of the pressure budget because it reduces player recovery or response.

---

# 19. Designing Boss mechanics

A Boss should not merely be an Elite with larger AP/SP.

Recommended sustained pressure composition:

```text
60–80% ordinary tank damage
10–25% periodic tank/raid pressure
10–25% encounter mechanics
```

Recommended T0.5 five-player values:

- ordinary tank pressure: approximately **900–1,300 / turn** total;
- tankbuster: approximately **1,400–2,000**;
- periodic raid hit: approximately **200–350 per player**;
- recovery windows should exist between the most dangerous mechanics.

At Mythic:

- ordinary direct attacks gain 25%;
- Boss challenge Damage Done means direct output is 1.50× the unmodified authored amount;
- Mythic +3 Hit increases reliability;
- upper-end Normal Boss stats should therefore not also be paired with constant high-strength tankbusters.

---

# 20. Raid-damage calibration

At T0.5, current Priest AoE healing can recover roughly the low-thousands across a five-player party in a strong healing turn, but this is mana-expensive.

Therefore:

- **200–300 damage per player** is meaningful but recoverable;
- **300–450 per player** is major raid pressure;
- repeated raid damage every turn should be substantially lower than burst raid damage;
- raid damage should not be stacked on top of maximum tank pressure every turn.

For ten players, add healer coverage and encounter mechanics rather than simply doubling damage received by each individual player.

---

# 21. Avoidance and hit

The offensive bands above are calibrated from landed damage.

Hit/avoidance should be treated as a reliability layer.

Current difficulty already adds:

- Heroic: no extra Hit;
- Mythic: +3 Hit.

Challenge templates may also add Hit/Crit.

Do not compensate for low hit chance by substantially inflating AP/SP unless that miss rate is an intentional core feature of the NPC.

A Boss should be dangerous because its attacks are meaningful, not because occasional hits are enormous after frequent misses.

---

# 22. Low-level progression is not yet calibrated

The Unit schema uses:

```text
resolved
= initialValue
+ (level - 1) × perLevelValue
```

The tables in this document are currently authoritative only for the Level-60 calibration point.

Do **not** derive `initialValue` and `perLevelValue` for these new ranges by blindly drawing a straight line from the old Level-1 values.

Doing so may create incorrect low-level survivability because:

- player HP progression is class-dependent;
- player gear contribution is non-linear;
- spell ranks introduce breakpoints;
- weapon damage changes non-linearly with gear;
- healer throughput changes with ranks and gear.

The next calibration stage should test at least:

1. Level 1 / starter gear;
2. a mid-level checkpoint;
3. Level 60 / T0.5;
4. Level 60 / T2.

Only then should permanent challenge-tier `initialValue` and `perLevelValue` values be finalized.

---

# 23. Required survivability simulation outputs

Every future NPC survivability simulation should report:

| Metric | Required |
|---|---|
| Challenge level | Yes |
| Role preset | Yes |
| Difficulty | Yes |
| Player count | Yes |
| Player gear tier | Yes |
| NPC runtime HP | Yes |
| NPC Armor/resistances | Yes |
| NPC MAP/RAP/SP/Healing Power | Yes |
| Weapon damage | Yes |
| Direct tank damage/turn | Yes |
| Periodic tank damage/turn | Yes |
| Raid damage/turn | Yes |
| Tank HP lost / turn | Yes |
| Sustainable healer throughput | Yes |
| Emergency healer throughput | Yes |
| Expected TTK | Yes |
| Tankbuster maximum | Yes |
| Relevant control/debuffs | Yes |
| Current-runtime caveats | Yes |

---

# 24. Immediate conclusions

The existing NPC variant balance table is now obsolete in several important respects.

At Level 60:

- Normal `~301 MAP/RAP` is at or below the bottom of the new ordinary-combatant range.
- Elite/Boss cannot continue sharing the same offensive AP/SP progression as Normal.
- old Boss Health around `6.5k` is roughly an ordinary-enemy durability value under current party output, not a Boss value.
- Boss Health should be approximately **75–90k for five players** and **150–180k for ten players** before difficulty bonuses, targeting roughly **10–15 turns** overall.
- Boss offensive power should remain roughly **650–1,000 MAP/RAP**, or **220–350 SP for a DoT-heavy caster**, rather than scaling damage solely through arbitrary Damage Done bonuses.
- Heroic/Mythic modifiers already add substantial pressure and must be included when choosing the upper end of each stat band.

Before these values are committed into default NPC data, the mitigation-model configuration and periodic-damage resolution behavior should be verified or corrected.