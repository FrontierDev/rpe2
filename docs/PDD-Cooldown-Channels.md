# RPE 2 — Cooldown Channels
## Product Design Document

**Status:** Draft  
**Target:** RPEngine 2.0 (`FrontierDev/rpe2`)  
**Branch:** `dev`  
**Scope:** Spell action economy, cooldown-channel ruleset configuration, spell authoring, runtime cooldown state, autopilot action planning  
**Explicitly out of scope:** Replacing spell cooldowns, replacing cooldown groups, changing cooldown duration units, redesigning the full spellcasting system

---

# 1. Purpose

RPE 2 currently models spell action economy through two spell flags:

```text
Triggers GCD
Ignore GCD
```

and separately supports:

```text
Cooldown Groups
```

This model is too limited for action economies where a character can have multiple independent categories of actions in the same turn, such as:

```text
Main Action
Bonus Action
Buff Action
Free Action
```

The system must therefore replace the current global-cooldown flag model with configurable **Cooldown Channels**.

Cooldown Groups remain a separate mechanic and continue to work exactly as a shared spell-category cooldown.

The resulting architecture must distinguish three independent concepts:

```text
Cooldown Channel
    = action economy / shared per-channel GCD

Spell Cooldown
    = this specific spell's reuse time

Cooldown Group
    = shared full cooldown among related spells
```

---

# 2. Goals

The implementation must:

1. Replace `Triggers GCD` / `Ignore GCD` with a single spell-level Cooldown Channel assignment.
2. Support up to ten Cooldown Channels per ruleset.
3. Allow each channel to have a configurable display name.
4. Allow each channel to configure whether spells assigned to it trigger that channel's GCD.
5. Provide sensible defaults:
   - Channel 1: Main Action, triggers channel GCD.
   - Channel 2: Bonus Action, triggers channel GCD.
   - Channel 3: Buff Action, triggers channel GCD.
   - Channel 4: Free Action, does not trigger channel GCD.
6. Preserve spell cooldowns, cooldown charges and cooldown groups.
7. Allow independent actions from different channels during the same turn.
8. Allow unlimited same-channel actions where that channel does not trigger a GCD, subject to spell cooldowns, cooldown groups, resources, conditions and other normal activation restrictions.
9. Update player spellcasting and NPC/autopilot action planning to use the same channel semantics.
10. Migrate existing spell data without silently changing current action-economy behaviour where avoidable.

---

# 3. Existing Behaviour

## 3.1 Spell GCD metadata

Spells currently contain:

```lua
triggersGCD = true
ignoreGCD = false
```

The spell inspector exposes these as two mutually exclusive checkboxes:

```text
Triggers GCD
Ignores GCD
```

The spellcasting helpers interpret a spell as using the global cooldown when:

```text
ignoreGCD ~= true
and
triggersGCD == true
```

---

## 3.2 Runtime cooldown state

The current cooldown runtime stores one global cooldown value for each event unit:

```lua
unitState = {
    spells = {},
    globalCooldownRemaining = 0,
    lastAdvancedTurnNumber = 0,
}
```

A normal GCD spell sets:

```lua
globalCooldownRemaining = 1
```

and any other spell that uses the global cooldown is blocked while that value is positive.

---

## 3.3 Existing Ignore GCD behaviour

`ignoreGCD` is not currently equivalent to a truly unlimited free action.

When an `ignoreGCD` spell is cast, other `ignoreGCD` spells receive a one-turn external lockout.

Therefore the existing model effectively supports two shared action pools:

```text
Normal GCD action
Ignore-GCD auxiliary action
```

This distinction is important for migration.

---

## 3.4 Cooldown Groups

Cooldown Groups are already independent of the global cooldown system.

A spell may define:

```lua
cooldown = 5
cooldownGroup = "blessings"
```

When cast, other known spells in the same cooldown group receive the triggering spell's full cooldown as an external lockout.

This behaviour must remain.

---

# 4. Core Design

Each spell belongs to exactly one Cooldown Channel:

```lua
cooldownChannel = 1
```

The channel identifier is numeric and stable.

The spell does **not** store the channel's display name or behaviour. Those are supplied by the active ruleset.

This separation allows a ruleset author to rename:

```text
Buff Action
```

to:

```text
Support Action
```

without editing every spell assigned to Channel 3.

---

# 5. Cooldown Channel Ruleset Model

A ruleset may configure channels 1 through 10.

Conceptually:

```lua
cooldownChannels = {
    [1] = {
        name = "Main Action",
        triggersGCD = true,
    },
    [2] = {
        name = "Bonus Action",
        triggersGCD = true,
    },
    [3] = {
        name = "Buff Action",
        triggersGCD = true,
    },
    [4] = {
        name = "Free Action",
        triggersGCD = false,
    },
}
```

The existing ruleset system is field-definition driven, so this should be represented by stable rule fields rather than introducing an arbitrary nested ruleset object solely for this feature.

Recommended ruleset category:

```text
Action Economy
```

with fields:

```text
Channel 1 Name
Channel 1 Triggers GCD

Channel 2 Name
Channel 2 Triggers GCD

...

Channel 10 Name
Channel 10 Triggers GCD
```

A blank channel name means that channel is not configured for ordinary authoring.

---

# 6. Default Channels

The default ruleset must define:

| Channel | Name | Triggers Channel GCD |
|---|---|---|
| 1 | Main Action | Yes |
| 2 | Bonus Action | Yes |
| 3 | Buff Action | Yes |
| 4 | Free Action | No |
| 5 | Blank | No |
| 6 | Blank | No |
| 7 | Blank | No |
| 8 | Blank | No |
| 9 | Blank | No |
| 10 | Blank | No |

The channel GCD duration remains one turn.

Configurable GCD duration is not part of this change.

---

# 7. Ruleset Helper API

The rest of the addon should not directly read individual channel rule keys.

Add helper APIs such as:

```lua
Ruleset.GetCooldownChannel(channelId, rulesetOverride)
Ruleset.GetCooldownChannels(rulesetOverride)
Ruleset.IsCooldownChannelEnabled(channelId, rulesetOverride)
Ruleset.DoesCooldownChannelTriggerGCD(channelId, rulesetOverride)
Ruleset.GetCooldownChannelName(channelId, rulesetOverride)
```

`GetCooldownChannel()` should return a normalized structure such as:

```lua
{
    id = 3,
    name = "Buff Action",
    triggersGCD = true,
    enabled = true,
}
```

This keeps channel semantics centralized and avoids duplicated ruleset parsing throughout spellcasting, UI and autopilot code.

---

# 8. Spell Data Model

Remove the action-economy fields:

```lua
triggersGCD
ignoreGCD
```

and replace them with:

```lua
cooldownChannel = 1
```

The normalized Spell model should guarantee a valid integer channel ID between 1 and 10.

Recommended normalization:

```text
missing / invalid / out-of-range
    -> Channel 1
```

This fallback is for malformed or legacy raw data only.

A spell referencing an otherwise valid but currently unnamed channel should retain that channel ID rather than being silently reassigned.

---

# 9. Spell Authoring UI

Remove from the Spell Casting inspector:

```text
Triggers GCD
Ignores GCD
```

Add to the Spell Cooldown inspector:

```text
Cooldown Channel
```

This should be a single-select dropdown populated from the active ruleset's configured channels.

Example:

```text
Cooldown Channel
[ Buff Action ▼ ]

Cooldown
[ 5 ]

Cooldown Group
[ blessings ]
```

The field belongs on the Cooldown page because the channel participates in cooldown/action-economy state rather than spell casting-time behaviour.

---

# 10. Unconfigured Channel Handling

If a spell contains:

```lua
cooldownChannel = 7
```

and Channel 7 is currently unnamed, the spell must not be silently moved to another channel.

The editor should display:

```text
Channel 7 (Unconfigured)
```

The runtime should reject activation with a clear reason such as:

```text
Cooldown channel is not configured by the active ruleset.
```

This prevents changing a ruleset from unexpectedly changing the action economy of existing spell definitions.

---

# 11. Runtime Cooldown State

Replace:

```lua
unitState = {
    spells = {},
    globalCooldownRemaining = 0,
    lastAdvancedTurnNumber = 0,
}
```

with:

```lua
unitState = {
    spells = {},
    channelCooldowns = {},
    lastAdvancedTurnNumber = 0,
}
```

Example:

```lua
channelCooldowns = {
    [1] = 1,
    [3] = 1,
}
```

This means that the unit has consumed its Main Action and Buff Action for the current turn, while other channels remain available.

---

# 12. Casting Eligibility

When resolving whether a spell can be cast:

```text
Resolve spell.cooldownChannel
        ↓
Resolve active ruleset channel
        ↓
Channel configured?
        ↓ no
reject activation
        ↓ yes
Does this channel trigger a GCD?
        ↓ yes
channelCooldowns[channelId] > 0?
        ↓ yes
reject activation
```

If the channel does not trigger a GCD, channel cooldown state does not block the spell.

Normal validation still applies afterward:

```text
Spell cooldown
Cooldown-group lockout
Charges
Conditions
Resources
Targets
Casting restrictions
```

---

# 13. Applying a Spell Cooldown

Casting a spell should apply three independent forms of cooldown state.

Example spell:

```lua
name = "Blessing of Might"
cooldownChannel = 3
cooldown = 5
cooldownGroup = "blessings"
```

Assume Channel 3 is:

```text
Buff Action
Triggers GCD = true
```

The result is:

```text
Blessing of Might
    -> own cooldown: 5 turns

All other blessings
    -> cooldown-group lockout: 5 turns

Channel 3
    -> channel GCD: 1 turn
```

No other channel is affected.

---

# 14. Free-Action Behaviour

For a spell assigned to:

```text
Channel 4 — Free Action
Triggers GCD = false
```

casting the spell does not write any Channel 4 GCD state.

Therefore another Channel 4 spell may be cast immediately in the same turn provided it passes all normal restrictions.

Examples of restrictions that still apply:

```text
Its own spell cooldown
Cooldown Group
Resources
Conditions
Charges
Target restrictions
An active persistent cast
Other explicit mechanics
```

The new Free Action behaviour is intentionally different from the old `ignoreGCD` behaviour.

---

# 15. Cooldown Advancement

On the caster's next eligible turn, every positive channel cooldown must be decremented using the same turn-advancement logic currently used for the global cooldown.

Conceptually:

```lua
for channelId, remaining in pairs(unitState.channelCooldowns) do
    local nextRemaining = math.max(0, remaining - advancedTurns)

    if nextRemaining > 0 then
        unitState.channelCooldowns[channelId] = nextRemaining
    else
        unitState.channelCooldowns[channelId] = nil
    end
end
```

Spell cooldowns and external cooldown-group lockouts continue advancing through their existing paths.

A unit cooldown bucket is removable only when:

```text
no active spell cooldown state
and
no active channel cooldown state
and
no other retained action-economy state
```

---

# 16. Cooldown Groups Remain Independent

Cooldown Groups must not be scoped by Cooldown Channel.

Example:

```text
Spell A
Channel 3
Cooldown Group = blessings
Cooldown = 5

Spell B
Channel 2
Cooldown Group = blessings
Cooldown = 5
```

Casting Spell A must still put Spell B on the full blessings group lockout even though Spell B belongs to a different Cooldown Channel.

Therefore:

```text
Cooldown Channel
≠
Cooldown Group
```

and no implementation should nest cooldown groups beneath channel state.

---

# 17. Tooltip and Failure Text

Replace generic messages such as:

```text
Global cooldown: 1 turn
On Global Cooldown
```

with channel-aware text.

Examples:

```text
Main Action cooldown: 1 turn
Buff Action cooldown: 1 turn
Bonus Action unavailable until next turn
```

The activation-state result should expose enough structured data for UI callers to render this without reparsing strings.

Recommended fields:

```lua
channelId
channelName
channelCooldownRemaining
```

and failure reason:

```text
channel-cooldown
```

instead of:

```text
global-cooldown
```

---

# 18. Cooldown State Signatures and Caching

Any cooldown signatures used to guard spell activation snapshots must incorporate the full channel cooldown map.

Do not hash only one global value.

Recommended stable signature order:

```text
Channel 1 remaining
Channel 2 remaining
...
Channel 10 remaining
```

or a sorted channel-ID map.

This is required so activation snapshots are invalidated when another action consumes the same channel between snapshot creation and execution.

---

# 19. Existing Spell-Reference Metadata Cache

The cooldown runtime currently builds metadata describing known caster spells, including:

```text
Cooldown Groups
Ignore-GCD spell refs
```

The `ignoreGCDSpellRefs` collection becomes unnecessary and should be removed.

The cooldown-group index remains.

If useful for efficient UI refresh or lockout propagation, the metadata cache may additionally index spells by channel:

```lua
spellsByCooldownChannel[channelId] = {
    spellRefA,
    spellRefB,
}
```

but channel GCD state itself should live once per channel rather than as per-spell external lockouts.

---

# 20. Migration of Existing Spell Data

Legacy spells must be migrated according to their current effective action economy.

Recommended mapping:

```text
triggersGCD = true
ignoreGCD = false
    -> Channel 1 (Main Action)
```

```text
triggersGCD = false
ignoreGCD = true
    -> Channel 2 (Bonus Action)
```

```text
triggersGCD = false
ignoreGCD = false
    -> Channel 4 (Free Action)
```

If malformed data contains:

```text
triggersGCD = true
ignoreGCD = true
```

prefer the existing normalization semantics where `ignoreGCD` wins and migrate to Channel 2.

This preserves the old shared auxiliary-action behaviour more accurately than mapping old `ignoreGCD` spells directly to the new unlimited Free Action channel.

---

# 21. Dataset Migration Strategy

Migration should occur through normal Spell normalization so imported legacy datasets remain usable.

When loading a raw spell:

```text
cooldownChannel present?
    ↓ yes
normalize it
    ↓ no
derive cooldownChannel from legacy GCD flags
```

When serializing/exporting a normalized Spell after the new schema is active:

```text
write cooldownChannel
omit triggersGCD
omit ignoreGCD
```

This avoids permanently carrying both systems.

Existing default dataset source files should also be rewritten to use `cooldownChannel` directly rather than relying on migration during every load.

---

# 22. Default Dataset Reclassification

After mechanical migration, default spells should be reviewed and deliberately assigned among:

```text
Main Action
Bonus Action
Buff Action
Free Action
```

In particular, spells currently marked `ignoreGCD = true` should not automatically remain Bonus Actions if their intended design is actually a Buff Action or Free Action.

Mechanical migration is for compatibility; semantic reclassification is a separate content pass.

---

# 23. Basic Attacks

The current basic-attack ruleset integration contains special logic that temporarily suppresses `triggersGCD` for basic attacks when:

```text
Basic Attacks Do Not Consume Global Cooldown
```

is enabled.

This must be removed or redesigned because mutating a spell's old GCD flag is incompatible with the Cooldown Channel model.

The existing basic-attack restrictions may remain:

```text
One basic attack type per turn
Basic attack damage-type restriction
Minimum personal cooldown behaviour
```

but whether a basic attack consumes action economy should come from its assigned Cooldown Channel.

The core model should not gain a new generic:

```lua
ignoreChannelGCD = true
```

escape hatch, because that would recreate the old flag architecture.

---

# 24. Basic Attack Default Assignment

If default RPE behaviour should continue allowing a basic attack without consuming the normal Main Action, the default basic-attack spells should be assigned to an appropriate separate channel.

The exact channel assignment should be explicit in the default dataset rather than generated dynamically at activation time.

If the old ruleset checkbox is retained temporarily for compatibility, it should be deprecated and migrated to channel assignment rather than continuing to alter live spell definitions.

---

# 25. Autopilot Action Economy

The current NPC action planner classifies candidates as:

```text
primary
auxiliary
terminal
```

based on:

```text
usesGlobalCooldown
ignoresGlobalCooldown
```

It also keeps ledger flags such as:

```lua
ignoreGCDCommitted
primaryGCDCommitted
```

and applies a fixed auxiliary-action cap.

This model must be replaced with channel reservations.

---

# 26. Autopilot Candidate Metadata

Replace:

```lua
usesGlobalCooldown
ignoresGlobalCooldown
```

with:

```lua
cooldownChannelId
cooldownChannelTriggersGCD
```

or a normalized channel object.

Example:

```lua
{
    spellRef = "...",
    cooldownChannelId = 3,
    cooldownChannelTriggersGCD = true,
    cooldownGroup = "blessings",
    ...
}
```

The planner should derive this from the same Ruleset helper API used by live spell activation.

---

# 27. Autopilot Reservation Ledger

Recommended ledger:

```lua
{
    availableResources = {},
    reservedResources = {},
    reservedCooldownGroups = {},
    reservedCooldownChannels = {},
    reservedSpellRefs = {},
    terminalCastCommitted = false,
}
```

For any selected action whose channel triggers a GCD:

```lua
reservedCooldownChannels[channelId] = spellRef
```

A second candidate using the same GCD-triggering channel is incompatible.

Candidates from different channels may coexist in the same planned turn.

Candidates in non-GCD channels do not reserve their channel.

---

# 28. Remove the Auxiliary Cap

The existing fixed limit on auxiliary actions is incompatible with configurable Cooldown Channels.

For example:

```text
Channel 2 — Bonus Action
Channel 3 — Buff Action
Channel 4 — Free Action
Channel 5 — Item Action
```

may legitimately allow several actions during the same turn.

Therefore action count should be constrained by:

```text
Channel reservations
Cooldown Groups
Spell cooldowns
Resources
Conditions
Persistent-cast behaviour
Tactical usefulness
```

not by a global arbitrary auxiliary-action count.

---

# 29. Persistent Casts

Persistent casts may remain terminal for action ordering if the current execution architecture requires them to begin last.

However, the planner should still be able to schedule legal actions from other channels before starting that persistent cast.

Example:

```text
Free Action
Buff Action
Main Action persistent cast
```

is valid if all three channels and spell states permit it.

---

# 30. Autopilot UI Annotations

Autopilot helper text currently labels auxiliary actions with wording such as:

```text
Off GCD
```

Replace this with the configured channel name where useful:

```text
Main Action
Bonus Action
Buff Action
Free Action
```

Do not infer action semantics from hard-coded channel numbers in UI code.

Always resolve the active ruleset's channel name.

---

# 31. Action Bar Behaviour

Action-bar spell availability must reflect only the spell's own channel cooldown.

Example state:

```text
Channel 1 consumed
Channel 3 consumed
Channel 4 free
```

Then:

```text
Channel 1 spells
    -> unavailable because Main Action is on cooldown

Channel 2 spells
    -> available

Channel 3 spells
    -> unavailable because Buff Action is on cooldown

Channel 4 spells
    -> available unless individually restricted
```

This should work identically for player-controlled units and explicit host-controlled NPC units.

---

# 32. Event/Turn Semantics

Cooldown Channels remain tied to the current turn-based cooldown architecture.

When a unit consumes a GCD-triggering channel during its eligible turn:

```text
channel cooldown = 1
```

The channel becomes available again when that unit's cooldown state advances into its next eligible turn.

No real-time cooldown timer is introduced.

---

# 33. NPCs and Players Use the Same Rules

Cooldown Channel behaviour must not diverge between:

```text
Local player
Controlled NPC
Autopilot NPC
Pet caster
Explicit host-controlled caster
```

All spell activation paths should ultimately resolve:

```text
spell.cooldownChannel
        +
active ruleset channel definition
```

through the same helper functions.

---

# 34. Ruleset Changes During an Event

Existing activation guards already include configuration revision state.

Changing the active ruleset or channel definitions must invalidate stale spell activation snapshots.

Existing active channel cooldown entries remain keyed by channel ID.

If a channel is renamed while state exists, the state remains valid because IDs, not names, are persisted in the runtime bucket.

If a channel becomes disabled while its cooldown is active, the spell should become unavailable due to the unconfigured-channel rule rather than being moved to another channel.

---

# 35. Naming and Terminology

User-facing terminology:

```text
Cooldown Channel
Channel GCD
Main Action
Bonus Action
Buff Action
Free Action
```

Avoid continuing to use generic:

```text
Global Cooldown
GCD spell
Off GCD
```

where a specific channel is known.

Internally, `GCD` may still be used to describe the one-turn shared cooldown property of a channel, but the system should make clear that the cooldown is scoped to a channel rather than global to the unit.

---

# 36. Proposed Code Changes

Primary files/modules expected to change:

```text
core/classes/Spell.lua
    Replace triggersGCD / ignoreGCD with cooldownChannel.
    Add legacy normalization migration.

core/internal/ruleset/Rules.lua
    Add Action Economy / Cooldown Channel rules.

core/internal/ruleset/Ruleset.lua
    Add channel normalization and helper APIs.

client/spellcasting/Helpers.lua
    Remove old GCD helper semantics.
    Add channel-resolution helpers if appropriate.

client/spellcasting/Cooldowns.lua
    Replace globalCooldownRemaining with channelCooldowns.
    Update eligibility, application, advancement, signatures,
    tooltip state and cleanup logic.

client/spellcasting/ExplicitCasterActivation.lua
    Remove temporary triggersGCD mutation.
    Rework basic-attack interaction.

client/ui/editor/inspectors/spell/page_InspectorSpellCasting.lua
    Remove GCD checkboxes.

client/ui/editor/inspectors/spell/page_InspectorSpellCooldown.lua
    Add Cooldown Channel dropdown.

client/ui/editor/inspectors/page_InspectorSpell.lua
    Refresh/enable the new channel control.
    Remove old checkbox refresh logic.

client/autopilot/ActionEconomy.lua
    Replace primary/auxiliary GCD ledger with channel reservations.

client/autopilot/SequencePlanning.lua
    Supply channel metadata instead of GCD booleans.

client/autopilot/Helper.lua
    Replace Off GCD annotation with channel-aware presentation.

data/default/Ruleset.lua
    Add default channel configuration.

data/default/*.lua
    Rewrite spell definitions to cooldownChannel.
```

Exact file boundaries may change if implementation uncovers a better existing abstraction, but the architecture should remain centralized around Ruleset channel resolution and the current cooldown runtime.

---

# 37. Compatibility Requirements

The change must preserve:

```text
Individual spell cooldowns
Cooldown charges
Cooldown Group lockouts
Turn-based cooldown advancement
Action-bar cooldown presentation
Explicit NPC casting
Player spellcasting
Pet spellcasting
Autopilot spell selection
Resource reservation
Persistent casts
Spell conditions
```

A Cooldown Channel must not bypass any of these systems.

---

# 38. Acceptance Criteria — Ruleset

The ruleset editor supports up to ten Cooldown Channels.

Each channel has:

```text
Name
Triggers GCD
```

The default ruleset provides:

```text
1 Main Action   — GCD
2 Bonus Action  — GCD
3 Buff Action   — GCD
4 Free Action   — no GCD
```

Changing a channel name immediately changes user-facing channel labels without requiring spell definitions to be edited.

Blank channels remain unavailable for normal spell authoring.

---

# 39. Acceptance Criteria — Spell Authoring

The Spell inspector no longer exposes:

```text
Triggers GCD
Ignores GCD
```

It exposes:

```text
Cooldown Channel
```

A spell stores a numeric channel ID.

Changing the active ruleset updates the channel dropdown labels.

A spell assigned to an unconfigured but valid channel retains that channel ID and displays it as unconfigured.

---

# 40. Acceptance Criteria — Runtime

Given:

```text
Channel 1 Main Action — GCD
Channel 2 Bonus Action — GCD
Channel 3 Buff Action — GCD
Channel 4 Free Action — no GCD
```

then within one turn:

```text
Casting one Channel 1 spell blocks other Channel 1 spells.
Casting one Channel 1 spell does not block Channels 2, 3 or 4.

Casting one Channel 2 spell blocks other Channel 2 spells.
Casting one Channel 2 spell does not block Channels 1, 3 or 4.

Casting one Channel 3 spell blocks other Channel 3 spells.
Casting one Channel 3 spell does not block Channels 1, 2 or 4.

Casting a Channel 4 spell does not block another Channel 4 spell.
```

On the caster's next eligible turn, consumed one-turn channel GCDs are cleared.

---

# 41. Acceptance Criteria — Cooldown Groups

Given:

```text
Blessing A
Channel 3
Cooldown = 5
Cooldown Group = blessings

Blessing B
Channel 3
Cooldown = 5
Cooldown Group = blessings

Buff C
Channel 3
Cooldown = 0
Cooldown Group = none
```

casting Blessing A must:

```text
Put Blessing A on its own 5-turn cooldown.
Put Blessing B on the blessings 5-turn group lockout.
Put Buff C only on the Channel 3 one-turn GCD.
```

If Blessing B is moved to Channel 2, casting Blessing A must still apply the blessings group lockout to Blessing B.

---

# 42. Acceptance Criteria — Free Actions

Given two Channel 4 Free Action spells with:

```text
no individual cooldown
no shared cooldown group
sufficient resources
valid conditions
```

both may be cast during the same turn.

If they share a cooldown group, casting the first may still block the second through that cooldown group.

If one has an individual cooldown, that spell still enters its normal cooldown after use.

---

# 43. Acceptance Criteria — Migration

Legacy data maps as follows:

```text
Normal GCD spell
    -> Channel 1

Ignore-GCD spell
    -> Channel 2

Neither flag enabled
    -> Channel 4
```

Legacy datasets load without Lua errors.

Newly exported datasets serialize only `cooldownChannel` for action economy.

Default datasets are updated to the new field rather than relying permanently on runtime migration.

---

# 44. Acceptance Criteria — Autopilot

NPC autopilot can plan one useful action from each available GCD-triggering channel in a turn.

It may plan multiple useful Free Actions when legal.

It must not plan two actions from the same GCD-triggering channel.

It must still prevent:

```text
Cooldown Group conflicts
Duplicate spell use where illegal
Resource overcommitment
Unavailable spell cooldowns
Invalid conditions
```

The old fixed auxiliary-action cap is no longer used.

Autopilot and manual activation agree on whether a sequence is legal.

---

# 45. Acceptance Criteria — Basic Attacks

Basic attacks no longer modify `triggersGCD` at runtime.

Their action-economy cost is determined by their configured Cooldown Channel.

Existing basic-attack-specific restrictions continue working independently of channel consumption.

No new generic spell flag is introduced to bypass a channel GCD.

---

# 46. Regression Tests

At minimum, deterministic tests or mocks should cover:

```text
Same-channel GCD conflict
Different-channel compatibility
Non-GCD Free Action chaining
Cooldown Group conflict on same channel
Cooldown Group conflict across channels
Individual spell cooldown + channel GCD
Charge spell + channel GCD
Channel cooldown advancement
Multiple advanced turns
Unconfigured channel rejection
Legacy triggersGCD migration
Legacy ignoreGCD migration
Legacy neither-flag migration
Activation signature invalidation after channel consumption
Autopilot same-channel rejection
Autopilot cross-channel sequencing
Autopilot unlimited legal Free Actions
Resource conflict across multiple channels
Persistent-cast sequence ordering
Basic attack channel handling
```

---

# 47. Non-Goals

This project does not:

```text
Remove Cooldown Groups
Replace spell cooldowns
Replace cooldown charges
Make channel GCD duration configurable
Introduce real-time cooldowns
Allow spells to belong to multiple channels
Allow a spell to bypass its own channel GCD through a per-spell flag
Create dataset-defined Cooldown Channel objects
Create per-class channel definitions
Change the Event turn model
```

Cooldown Channels are ruleset action-economy configuration, not dataset entities.

---

# 48. Principal Architectural Decisions

**Cooldown Channels replace `Triggers GCD` and `Ignore GCD`; they do not sit on top of them.**

**Each spell belongs to one stable numeric channel.**

**Channel names and GCD behaviour belong to the active ruleset.**

**Up to ten channel slots are supported.**

**Channels 1–4 default to Main Action, Bonus Action, Buff Action and Free Action.**

**A channel whose `Triggers GCD` setting is false does not create a one-turn peer lockout.**

**Cooldown Groups remain global across channels and retain their current full-lockout semantics.**

**Spell cooldowns, charges and cooldown groups remain independent of channel GCD state.**

**The runtime stores cooldown state once per channel, not by applying fake lockouts to every spell in that channel.**

**The ruleset layer owns normalized Cooldown Channel resolution so UI, spellcasting and autopilot use one interpretation.**

**Legacy `ignoreGCD` spells migrate to Bonus Action rather than Free Action because the existing system already gives them a shared one-turn peer lockout.**

**Autopilot becomes channel-aware and no longer relies on primary/auxiliary GCD classification or a fixed auxiliary-action cap.**

**Basic attacks express their action-economy cost through channel assignment rather than runtime mutation of spell GCD flags.**

This produces a configurable action economy while preserving RPE 2's existing cooldown-group, spell-cooldown and turn-based combat architecture.
