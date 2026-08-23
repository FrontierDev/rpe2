## Goal
Audit Tasks 1–11 as one coherent Guild Rank/Achievement implementation and fix **concrete defects only**.

Depends on: #10, #11, #12, #13, #14, #15, #16, #17, #18, #19, #20

Do not start this issue until Tasks 1–11 are implemented and pushed.

## Required audit
### User-facing terminology
Search user-facing UI/text for stale:

```text
Guild Setting
Guild Settings
Minimum Guild Rank
```

Internal compatibility identifiers such as:

```text
GuildSetting
guildSettings
requiredGuildRankIndex
```

may remain where required for storage/backward compatibility, but product UI must use **Guild Rank** terminology and must not expose the superseded Requisition-level Minimum Guild Rank authoring/eligibility model.

### Schema and migration smoke test
Verify backward-compatible normalization for:

```text
Profile schema 5 -> 6
Dataset schema 15 -> 16
old GuildSetting without wowGuildRankIndices
old Requisitions containing requiredGuildRankIndex
existing profile.guild.byGuild nested state
```

Confirm:
- existing Achievement/Profile state still loads;
- existing Requisition/Daily Reward/Progression definitions survive;
- old Guild nested state is preserved;
- Inventory remains independent/untouched by migration;
- future higher schema markers are not lowered;
- migration never automatically assigns an RPE Guild Rank.

### Dataset round-trip
Construct or inspect a representative Dataset containing:
- multiple RPE Guild Ranks;
- two RPE Guild Ranks mapping to the same WoW guild rank;
- one unrestricted Guild Rank with empty `wowGuildRankIndices`;
- Requisitions with built-in and dataset Currency refs;
- Daily item/currency rewards;
- Progression entries/spell refs;
- Achievements referenced by the runtime/admin path.

Export/import and verify definitions, qualified refs, mappings and legacy compatibility fields survive appropriately.

### Guild Rank catalogue
Verify:
- exact `guildName` catalogue takes priority over the generic catalogue **as a set**;
- multiple exact ranks are returned without conflict;
- multiple generic ranks are returned when no exact catalogue exists;
- one WoW rank may have multiple eligible RPE Guild Ranks;
- empty `wowGuildRankIndices` means unrestricted;
- eligibility uses exact index membership, not numeric hierarchy;
- there is no implicit RPE rank inheritance.

### Manual assignment model
Verify:
- a character has at most one assigned RPE Guild Rank per guild;
- assignment is set/cleared only by the explicit officer admin flow;
- login, roster refresh and WoW rank changes never automatically assign/remap/clear the rank;
- stale/invalid assignments return explicit status without mutation;
- rank assignment persists per guild;
- receiver validates applicability/eligibility using its own live state.

### Guild window/UI
Smoke-test:
- Launcher -> Guild;
- `/rpe guild`;
- Guild -> Requisitions;
- Guild -> Progression;
- Guild -> Admin;
- assigned/unassigned/invalid rank status;
- Admin roster refresh/officer gating.

Multiple catalogue ranks must not produce the old Phase 1 conflict state.

### Requisition runtime
Verify:
- only the valid assigned rank's Requisitions are usable;
- Requisition from another rank is rejected;
- legacy `requiredGuildRankIndex` is ignored by runtime;
- multiple currency costs validate before spending;
- built-in `copper` works;
- character lifetime limits are rank/Requisition scoped;
- Inventory grants use `Client.Inventory.AddItem()`;
- failures cannot leave partial deductions;
- usage persists across reload/relog.

### Daily Reward runtime
Verify:
- rewards come only from the valid assigned rank;
- no assigned/valid rank gives no reward;
- item/currency rewards use canonical APIs;
- claim is one per character/guild/calendar day;
- `/reload`, relog and repeated guild events cannot duplicate the claim;
- changing RPE Guild Rank after claiming does not allow a second claim that day;
- `dailyRewardRankRef` records which rank supplied the reward.

### Achievement runtime
Verify:
- `currency_gain` uses actual positive applied gain after caps;
- Set/Spend does not count as earning;
- `rpe_kill` comes only from authoritative alive -> dead transition;
- already-dead updates do not count again;
- criterion filters work;
- `rpe_event_complete` uses the authoritative event-completion path;
- `achievement_earned` meta progress works;
- `completedAt` is transition-based and persists;
- completed Achievements do not re-announce on load;
- Guild/Raid announcements are normal visible chat;
- manual `Grant()` uses normal completion handling.

### Guild Admin security boundary
For **every** remote mutation (Guild Rank, Achievement, Skill, Item, Progression), verify the target member's client independently derives/validates:

```text
sender identity from transport
same-guild membership
sender WoW officer capability
target-self state
requested object/reference validity
operation-specific numeric/state validity
```

Do not rely on prior query success, sender-supplied officer flags or UI gating.

Verify:
- explicit acknowledgement for mutations;
- no optimistic success in Admin UI;
- online compatible members only;
- no direct remote SavedVariable writes.

### Progression runtime/admin
Verify:
- only the valid assigned rank's Progression is active/displayed;
- state is stored under `progression[guildRankRef]`;
- switching ranks preserves prior rank state but activates only the new/current rank;
- locked entries cannot be selected;
- selected spells must exist in configured `spellRefs`;
- UI supports more than exactly three entries/slots;
- officer mutations are receiver-validated and acknowledged;
- core contains no campaign-specific rank/oath terminology.

### Load order and explicit integration maps
Review `RPEngine_Dev.toc` and all explicit collection/inspector/refresh maps affected by the revision.

Verify:
- classes load before instantiation;
- Profile Guild/Achievement modules load before client/UI consumers;
- Guild/Achievement pages load before their windows;
- Data Editor pages/inspectors load before use;
- new runtime modules load before hooks/callers that require them;
- `guildSettings` remains integrated in Database/Data Editor/dependency flows.

### Non-goal audit
Search the implementation and ensure it has **not** introduced:

```text
automatic RPE Guild Rank assignment
automatic rank remapping/clearing
multiple simultaneous assigned RPE Guild Ranks
implicit RPE Guild Rank hierarchy/inheritance
offline remote Profile mutation
direct remote SavedVariable writes
another Guild Admin messaging subsystem
another Inventory/currency storage system
```

## Definition of done
- [ ] Existing Phase 1 data remains loadable.
- [ ] Guild Rank is the external terminology.
- [ ] Dataset mappings support many RPE ranks per WoW rank.
- [ ] Character rank is officer-assigned only.
- [ ] Rank assignment is stored per guild and receiver-validated.
- [ ] Requisitions are rank-scoped and transactional.
- [ ] Daily Rewards are rank-scoped and once-per-guild/day.
- [ ] Achievement runtime works without Guild Rank coupling.
- [ ] General Guild Admin mutations are receiver-validated.
- [ ] Progression is rank-scoped and persistent.
- [ ] No prohibited automatic rank behavior exists.
- [ ] Load order, schemas, exports/imports and dependency handling remain coherent.

## Coding-agent instructions
Treat the current `FrontierDev/rpe2` repository, revised `RPE2-Achievements-Guild-Systems-PDD.md`, and completed Tasks 1–11 as authoritative. Compare every checklist item against the implemented state. Fix concrete omissions/regressions only; do not expand scope or redesign working systems during the audit. Report the audit performed, files changed, validation results and any unresolved deviation before considering the task complete.