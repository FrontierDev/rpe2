# RPE 2 — Cooldown Channels Implementation Plan

**Status:** Implementation-ready  
**Target branch:** `dev`  
**PDD:** `docs/PDD-Cooldown-Channels.md`  
**Tracker:** #363  
**Implementation issues:** #355–#362

---

## 1. Purpose

This plan implements the cooldown-channel system without performing a risky one-step rewrite of spell data and runtime behavior.

The final system replaces spell-level:

```text
Triggers GCD
Ignores GCD
```

with one stable numeric spell property:

```lua
cooldownChannel = 1
```

The active ruleset defines up to ten cooldown channels. The default configuration is:

| ID | Name | Triggers channel GCD |
|---:|---|---|
| 1 | Main Action | yes |
| 2 | Bonus Action | yes |
| 3 | Buff Action | yes |
| 4 | Free Action | no |
| 5–10 | unconfigured | no |

Individual spell cooldowns, charges and cooldown groups remain independent of cooldown channels.

---

## 2. Safety strategy

The implementation is deliberately split into compatibility-first stages.

The critical rule is:

> **Do not migrate the default spell data until the ruleset model, Spell schema, live runtime, UI, basic-attack handling and autopilot are already channel-aware and have passed the pre-migration regression gate.**

Issues #355–#361 therefore continue to load the existing default spell records through a temporary legacy mapping. Only #362 rewrites the shipped default spell data.

This produces the following transition:

```text
Existing spell data
    triggersGCD / ignoreGCD
              │
              ▼
#356 compatibility resolver
              │
              ▼
Channel-native runtime/UI/autopilot
              │
              ▼
#361 regression gate
              │
              ▼
#362 explicit default-data migration
              │
              ▼
Canonical cooldownChannel data
```

At no point should two independent runtime action-economy systems exist.

---

## 3. Implementation order

### Step 1 — Ruleset channel definitions and resolver APIs

**Issue:** #355

Add the Action Economy ruleset configuration and canonical channel resolver helpers.

This establishes stable IDs and default behavior before any Spell or runtime code depends on channels.

Deliverables:

- ten fixed channel slots;
- channel name and channel-GCD behavior for each slot;
- default Main / Bonus / Buff / Free channels;
- centralized normalized resolver APIs;
- default Ruleset data updated through existing versioning.

**Gate:** no Spell/runtime behavior changes.

---

### Step 2 — Spell `cooldownChannel` schema with legacy compatibility

**Issue:** #356

Add the canonical spell-side channel field and one temporary compatibility path for existing data.

Legacy inference while the default datasets remain unmigrated:

```text
triggersGCD=true,  ignoreGCD=false -> Channel 1
triggersGCD=false, ignoreGCD=true  -> Channel 2
triggersGCD=false, ignoreGCD=false -> Channel 4
triggersGCD=true,  ignoreGCD=true  -> Channel 2
```

Explicit `cooldownChannel` always wins over legacy inference.

**Gate:** no cooldown-state changes and no default dataset migration.

---

### Step 3 — Live spellcasting runtime cutover

**Issue:** #357

Replace the single per-unit global GCD state with sparse per-channel cooldown state:

```lua
unitState.channelCooldowns[channelId] = remainingTurns
```

A spell cast must:

1. apply its own cooldown/charge behavior;
2. apply its existing cooldown-group behavior;
3. apply a one-turn cooldown only to its own configured channel when that channel has `triggersGCD=true`.

Cooldown groups remain global across channels.

The old `ignoreGCD` peer-lockout path is removed from live runtime behavior because Channel 2 now provides that limit directly.

**Gate:** manual/player spellcasting works against still-legacy default data through #356.

---

### Step 4 — Authoring and presentation UI

**Issue:** #358

Remove the spell-editor `Triggers GCD` and `Ignores GCD` controls and replace them with one Ruleset-driven **Cooldown Channel** dropdown.

Also make action-bar/cooldown text channel-aware, for example:

```text
Buff Action cooldown: 1 turn
```

An unconfigured stored channel must remain visible as an invalid assignment rather than being silently remapped.

Opening a legacy spell in the editor must not migrate it merely by refreshing the inspector.

**Gate:** UI can author explicit channels, but shipped default spells remain unchanged.

---

### Step 5 — Basic-attack compatibility cleanup

**Issue:** #359

Remove the current strategy that temporarily changes `spell.triggersGCD` for basic attacks.

Preserve the independent basic-attack rule that restricts basic attacks by damage type/per turn, but do not introduce a generic `ignoreChannelGCD` escape hatch.

The final Free Action assignments for Core auto-attacks are intentionally deferred to #362.

**Gate:** no shared Spell mutation and no Core data migration.

---

### Step 6 — Autopilot action-economy conversion

**Issue:** #360

Replace autopilot's `primary`/`auxiliary` GCD model with channel reservations.

The planner ledger becomes channel-oriented:

```lua
reservedCooldownChannels = {}
reservedCooldownGroups = {}
reservedSpellRefs = {}
reservedResources = {}
```

Rules:

- one selected action per triggering channel;
- different triggering channels are independently available;
- non-triggering channels are not reserved by channel;
- cooldown-group and resource conflicts still apply;
- remove the arbitrary two-auxiliary-action cap;
- persistent casts may remain terminal for execution ordering but still reserve only their own action channel.

**Gate:** planner legality must match live activation while still using legacy default data through #356.

---

### Step 7 — Pre-migration integration and regression gate

**Issue:** #361

Perform a repository-wide audit and integrated regression pass before changing default data.

Validate all of:

- manual/player casts;
- explicit NPC/host casts;
- item-use spells;
- action-bar availability;
- cooldown advancement/reset/pruning;
- charges;
- cooldown groups across different channels;
- active Ruleset channel changes;
- autopilot/live-activation parity;
- event lifecycle/reset behavior.

At the end of this issue, runtime/UI/autopilot must no longer make decisions directly from spell-level `triggersGCD` or `ignoreGCD`.

The only remaining legacy references should be:

1. the centralized old-data import/normalization fallback; and
2. the still-unmigrated default dataset records.

**Hard gate:** #362 cannot begin until this issue passes.

---

### Step 8 — Final default-data migration and schema cutover

**Issue:** #362

This is the only issue permitted to migrate the shipped default spell records.

At the issue-creation baseline there are **185 default Spell entries**:

| Dataset | Spell count |
|---|---:|
| Core | 8 |
| Mage | 22 |
| Paladin | 35 |
| Priest | 21 |
| Rogue | 17 |
| Warrior | 22 |
| Alchemy | 35 |
| Engineering | 25 |
| **Total** | **185** |

Issue #362 contains the authoritative spell-by-spell assignment table, including IDs for the Core/class datasets and every Alchemy/Engineering spell name.

The migration principles are:

- **Channel 1 — Main Action:** primary attacks, direct heals, primary control/actions;
- **Channel 2 — Bonus Action:** auxiliary attacks/control/reactions and all current Alchemy/Engineering item-use spells;
- **Channel 3 — Buff Action:** beneficial aura/buff/defensive setup spells, including all Paladin Blessings;
- **Channel 4 — Free Action:** the Core basic auto-attacks that already have an independent basic-attack usage restriction.

The item-use decision is intentional: old potion/bomb actions are migrated to **Bonus Action**, not Free Action, to avoid accidentally making every consumable/device unlimited within one turn.

The issue also:

- removes spell-level `triggersGCD` / `ignoreGCD` from shipped defaults;
- increments only affected default dataset versions;
- changes current Spell serialization to `cooldownChannel` only;
- retains narrow old-data read/import compatibility;
- removes the obsolete `basic_attacks_do_not_consume_gcd` Ruleset option now that basic attacks explicitly occupy Free Action;
- verifies all current default spells are covered even if new spells were added after this plan was written.

---

## 4. Cooldown-group invariants

Cooldown channels do not replace or weaken cooldown groups.

For example:

```text
Blessing of Might
  cooldownChannel = 3       -- Buff Action
  cooldown = N
  cooldownGroup = blessings
```

Casting it should produce:

```text
Blessing of Might own cooldown
        +
full blessings group lockout on other Blessings
        +
1-turn Channel 3 cooldown on unrelated Buff Action spells
```

A spell on Channel 1 or Channel 2 remains available unless another independent rule blocks it.

If two spells with the same cooldown group are assigned to different channels, the cooldown group must still lock both.

---

## 5. Required end-state architecture

After #362:

### Ruleset

Owns channel definitions:

```lua
channel = {
    id = 3,
    name = "Buff Action",
    triggersGCD = true,
}
```

### Spell

Owns only channel identity:

```lua
cooldownChannel = 3
```

### Runtime EventUnit cooldown state

Owns active channel cooldowns:

```lua
channelCooldowns = {
    [1] = 1,
    [3] = 1,
}
```

### Spell cooldown state

Continues to own:

- spell cooldown/recharge;
- charges;
- external cooldown-group lockout.

### Autopilot

Uses the same channel IDs/definitions and live activation legality rather than maintaining a parallel primary/auxiliary model.

---

## 6. Regression requirements

Before considering the project complete, verify at minimum:

1. Main Action locks only Main Action.
2. Bonus Action locks only Bonus Action.
3. Buff Action locks only Buff Action.
4. Multiple Free Actions are channel-legal when no other rule blocks them.
5. Individual cooldowns still block Free Action spells.
6. Charges still recharge normally.
7. Cooldown groups block peers regardless of channel.
8. Paladin Blessings apply both their group cooldown and Buff Action channel cooldown correctly.
9. Potions and Engineering devices consume Bonus Action and retain their existing own/group cooldowns.
10. Basic auto-attacks use Free Action while retaining their separate per-turn/type restrictions.
11. Player and host-controlled NPC casting use the same channel rules.
12. Autopilot never schedules two actions in the same triggering channel.
13. Autopilot can schedule Main + Bonus + Buff together when useful and legal.
14. Autopilot may schedule multiple Free Actions when each is otherwise legal/useful.
15. Active channel renames do not change stored spell IDs.
16. Disabling a used channel produces a safe explicit unavailable state.
17. Event reset clears channel cooldown state.
18. Old imported datasets with only legacy GCD flags still normalize through the compatibility boundary.
19. New exports do not perpetuate legacy spell-level GCD fields.

---

## 7. Scope control for implementation agents

Each numbered issue is intentionally sized for GPT-5.6 Luna High.

For every issue:

1. read the current version of every affected file before editing;
2. trace the exact current call paths rather than relying solely on this plan/PDD;
3. implement only that issue's scope;
4. review the resulting diff for architectural expansion;
5. identify regressions for every modified API/call site;
6. exercise pure logic with deterministic mocks/tests where practical;
7. verify the issue acceptance criteria;
8. stop after the issue is complete.

Do not opportunistically begin the next issue.

Most importantly, **do not move default spells to new cooldown channels before #362**.
