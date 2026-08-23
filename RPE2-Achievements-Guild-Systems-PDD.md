# RPE 2 — Achievements and Guild Systems
## Product Design Document

**Status:** Draft  
**Target:** RPEngine 2.0 (`FrontierDev/rpe2`)  
**Scope:** Achievements, Guild Requisitions, Daily Rewards, Guild Administration, Guild Progression  
**Reference addons:** `old_crusadetoolkit`, `gns_mekkatorque`  
**Explicitly out of scope:** Bestiary, Quest Log

---

# 1. Purpose

This project extends RPE 2 with two related systems:

1. **Achievements**
   - Defined as dataset content.
   - Progress and completion stored per character Profile.
   - Displayed in a new Profile → Achievements tab.
   - Can progress automatically from RPE gameplay.
   - Can be granted manually by guild officers.
   - Newly earned achievements can be announced to Guild and Raid chat.

2. **Guild Systems**
   - A new top-level RPE **Guild** window.
   - Dataset-defined guild settings.
   - Requisitions.
   - Daily login rewards.
   - Guild-specific character progression.
   - Officer administration of online members' RPE characters.

The implementation must build on RPE 2's existing Database, Profile, Registry, Inventory, Runtime, UI and Comms systems rather than importing the architecture of either reference addon.

---

# 2. Existing RPE 2 Architecture

## 2.1 Achievements already exist as dataset objects

RPE 2 already defines:

```lua
Achievement {
    id
    name
    description
    icon
    criteria
    rewards
    tags
}
```

and registers the class as:

```lua
Addon.Internal.Database.Classes.Achievement
```

The class already serializes `criteria`, `rewards` and `tags`, but currently performs no normalization or semantic interpretation of these fields.

Achievements are already a recognized dataset collection in the Database and Data Editor.

However, the current Achievement editor is unfinished. It can create Achievement entries through the generic dataset tooling, but the page currently displays:

> `Achievement icon grid will appear here.`

There is also no Achievement inspector mapping in the Data Editor.

Therefore Phase 1 must include **finishing Achievement authoring**, not merely adding the character-facing Achievement page.

---

## 2.2 Profiles are centrally normalized in Database.lua

RPE character Profiles currently contain state such as:

- race/class;
- equipment;
- spellbook;
- traits;
- skill levels;
- action bars;
- stat bonuses;
- currencies.

There is currently no Achievement or Guild state in the Profile. Profile creation and normalization are centralized in `core/internal/database/Database.lua`.

The new systems should therefore extend the existing Profile record rather than introduce separate SavedVariables for achievement/guild character state.

Proposed additions:

```lua
profile.achievements = {}
profile.guild = {}
```

The Profile database schema should be incremented accordingly.

---

## 2.3 Inventory is not part of the Profile

This is important for Guild Admin and rewards.

RPE character inventory is stored independently in:

```text
RPEngineInventoryDB
```

rather than inside `RPEngineProfilesDB`. The canonical item award path is:

```lua
Addon.Client.Inventory.AddItem(...)
```

which handles:

- dataset/item identity;
- stack merging;
- maximum stack sizes;
- bind-on-pickup;
- inventory change notifications.

Therefore:

**Items awarded by Requisitions, Daily Rewards or Guild Admin must use `Client.Inventory.AddItem()`. They must not be written into the Profile.**

---

## 2.4 Currencies already have a suitable abstraction

RPE supports:

### Built-in currencies

```text
copper
valor
justice
honor
conquest
```

### Dataset currencies

```text
datasetId:currencyId
```

The Profile system already exposes:

```lua
Profile.GetCurrencyAmount(...)
Profile.SetCurrencyAmount(...)
Profile.AddCurrencyAmount(...)
Profile.SpendCurrencyAmount(...)
Profile.ResolveCurrencyDefinition(...)
```

including currency caps and support for both built-in and dataset-defined currencies.

Guild Requisition costs should therefore store **currency references**, not a special Guild currency representation.

Example:

```lua
costs = {
    {
        currencyRef = "copper",
        amount = 50000,
    },
    {
        currencyRef = "campaignData:commendation",
        amount = 2,
    },
}
```

---

## 2.5 Skills already have Profile mutation APIs

RPE exposes Profile skill state through:

```lua
Profile.GetSkillLevel(skillRef)
Profile.SetSkillLevel(skillRef, value)
Profile.ClearSkillLevel(skillRef)
```

and the Registry can resolve dataset-qualified Skill references. Skills themselves remain dataset definitions.

Guild Admin should therefore modify skills through these APIs.

---

## 2.6 Dataset-qualified references are already the RPE convention

The Registry consistently resolves entries using:

```text
datasetId:entryId
```

for Items, Skills, Spells, Traits, Stats, etc.

The same convention should be extended to:

```text
datasetId:achievementId
datasetId:guildSettingId
```

and all GuildSetting references to Items, Currencies, Spells or Achievements should use the existing qualified-reference format.

---

## 2.7 RPE already has the communications infrastructure needed for Guild Admin

RPE has a central addon messaging layer with:

- registered opcodes;
- serialization;
- chunking;
- dispatch;
- channel messages;
- targeted addon messages;
- request/response style operations.

The current operation table reaches opcode 23 and handles RPE session, event, combat, resource and combat-log traffic.

`Comms.SendMessage()` already accepts a Blizzard addon-message distribution and target, so Guild Administration should extend this protocol and use targeted `WHISPER` addon messages rather than creating another messaging subsystem.

---

# 3. Core Design Principle

The architecture should maintain a strict distinction:

```text
Dataset                        Character State
────────────────────           ──────────────────────────
Achievement definition   ->    Achievement progress
GuildSetting              ->    Requisition usage
                              Daily reward claim
                              Progression state
```

A Dataset describes **what exists and how it behaves**.

A Profile describes **what this character has done**.

No player-specific completion state should ever be serialized into an Achievement or GuildSetting dataset object.

---

# 4. Achievement Definition Model

## 4.1 Do not directly port CrusadeToolkit's `Type`

CrusadeToolkit supports four Achievement types:

```text
single
counter
checklist
meta
```

and has separate completion logic for each.

Those concepts are useful, but RPE 2 already has a more suitable starting point: an Achievement owns an array called `criteria`.

Rather than introducing another top-level:

```lua
type = "counter"
```

RPE 2 should make each criterion independently describable.

This allows all four CrusadeToolkit behaviours to emerge naturally from one model.

---

# 5. Proposed Achievement Criteria Schema

An Achievement remains:

```lua
Achievement {
    id = "boss_slayer",
    name = "Boss Slayer",
    description = "Defeat ten enemies during RPE events.",
    icon = "...",

    criteria = {
        ...
    },

    rewards = {},
    tags = {},
}
```

Each criterion becomes:

```lua
{
    id = "kill_enemies",
    description = "Defeat enemies",
    trigger = "rpe_kill",
    goal = 10,

    filters = {
        enemyOnly = true,
    },
}
```

Every criterion must have a **stable ID**.

Criterion progress must be keyed by that ID rather than by array position so editing or reordering criteria does not invalidate existing character progress.

---

## 5.1 Single achievement

```lua
criteria = {
    {
        id = "complete_event",
        trigger = "rpe_event_complete",
        goal = 1,
    },
}
```

---

## 5.2 Counter achievement

```lua
criteria = {
    {
        id = "kills",
        trigger = "rpe_kill",
        goal = 100,
    },
}
```

---

## 5.3 Checklist achievement

```lua
criteria = {
    {
        id = "boss_one",
        trigger = "rpe_kill",
        goal = 1,
        filters = {
            unitRef = "campaign:boss_one",
        },
    },
    {
        id = "boss_two",
        trigger = "rpe_kill",
        goal = 1,
        filters = {
            unitRef = "campaign:boss_two",
        },
    },
}
```

Completion requires every criterion to be complete.

---

## 5.4 Meta achievement

```lua
criteria = {
    {
        id = "achievement_one",
        trigger = "achievement_earned",
        goal = 1,
        filters = {
            achievementRef = "campaign:achievement_one",
        },
    },
    {
        id = "achievement_two",
        trigger = "achievement_earned",
        goal = 1,
        filters = {
            achievementRef = "campaign:achievement_two",
        },
    },
}
```

This replaces CrusadeToolkit's name-based `Dependencies` system with stable RPE dataset references.

---

# 6. Initial Achievement Trigger Types

Phase 3 should implement the following trigger contract:

```text
manual
currency_gain
rpe_kill
rpe_event_complete
achievement_earned
```

The engine should be designed so new triggers can later be added without changing the Achievement state model.

Likely future triggers include:

```text
item_gain
skill_gain
rpe_boss_kill
rpe_damage
rpe_healing
rpe_event_started
```

but they are not required for the initial implementation.

CrusadeToolkit demonstrates the value of a centralized trigger map covering kills, bosses, event completion, initiative results and other event actions. RPE should retain this event-driven approach, but the mapping should come from dataset Achievement criteria rather than a hard-coded table of Achievement names.

---

# 7. Achievement Profile State

Add:

```lua
profile.achievements = {
    ["campaign:boss_slayer"] = {
        criteria = {
            ["kills"] = 7,
        },

        completedAt = nil,
    },
}
```

Completed example:

```lua
profile.achievements["campaign:boss_slayer"] = {
    criteria = {
        ["kills"] = 10,
    },

    completedAt = 1787481200,
}
```

A separate `completed = true` field is unnecessary because:

```lua
completedAt ~= nil
```

is sufficient.

This state belongs in `RPEngineProfilesDB`.

---

# 8. Achievement Runtime

Introduce a proposed runtime module:

```text
client/client_Achievements.lua
```

or an equivalent location consistent with the final code organization.

Responsibilities:

```text
Build criterion trigger index
Receive trigger events
Filter matching criteria
Update Profile criterion progress
Check Achievement completion
Trigger dependent/meta achievements
Refresh Profile UI
Broadcast newly earned achievements
```

The runtime should build its index from:

```lua
Registry:GetActivatedDatasets()
```

which is already the standard RPE mechanism for working with active dataset content.

Conceptually:

```text
currency_gain
    -> campaign:wealthy / copper_earned
    -> guild:treasurer / commendations

rpe_kill
    -> campaign:first_blood / kill
    -> campaign:slayer / kills
```

This avoids scanning every Achievement every time something happens.

---

# 9. Currency Gain Trigger

The correct integration point is:

```lua
Profile.AddCurrencyAmount(...)
```

not:

```lua
Profile.SetCurrencyAmount(...)
```

because `SetCurrencyAmount()` is also used to produce decreases, administrative changes and other absolute assignments.

`SpendCurrencyAmount()` already has a separate path.

`AddCurrencyAmount()` should calculate the **actual applied increase**:

```lua
previousAmount
updatedAmount
actualGain = updatedAmount - previousAmount
```

This matters when a currency reaches its configured maximum.

Then:

```lua
Achievements:Trigger("currency_gain", {
    currencyRef = normalizedCurrencyRef,
    amount = actualGain,
    source = source,
})
```

The existing API should gain an optional third argument:

```lua
Profile.AddCurrencyAmount(currencyRef, amount, options)
```

for example:

```lua
{
    source = "daily_reward"
}
```

This is backward-compatible with all existing two-argument calls.

---

# 10. RPE Kill Trigger

This requires particular care because RPE combat does not treat the initial damage preview as authoritative.

The Damage system explicitly previews resource changes locally; a resource change becomes authoritative when the corresponding `RESOURCE_DELTA` returns through the normal RPE client path.

Current death handling occurs after resource deltas are applied to the EventUnit. `client_Resources.lua` then checks:

```lua
Combat:IsUnitDead(...)
```

and calls:

```lua
Combat:HandleUnitDeath(...)
```

Therefore **Achievements must not be awarded directly from the preliminary Damage effect.**

Doing so could grant an Achievement for a lethal preview that was never committed.

Instead, the resource-delta application path should detect:

```text
alive before delta
        ↓
authoritative RESOURCE_DELTA
        ↓
dead after delta
```

Only this transition generates:

```text
rpe_kill
```

The resource-delta handling already has:

- event state;
- target EventUnit;
- target event ID;
- applied resource deltas;
- addon-message sender.

That sender can be compared with the local player to determine whether this player's committed action produced the kill.

Example trigger payload:

```lua
{
    eventId = eventState.id,
    targetEventId = targetUnit.eventID,
    targetUnitRef = targetUnit.unitRef,
    targetName = targetUnit.name,
    targetTeam = targetUnit.team,
    targetIsPlayer = targetUnit.isPlayer == true,
    killerName = sender,
}
```

The transition check is important because further updates to a unit that is already dead must not count as additional kills.

---

# 11. Achievement Completion

An Achievement completes when **all of its criteria are satisfied**.

Completion must be transition-based:

```text
not complete
    ↓
complete
```

Only that transition should:

1. set `completedAt`;
2. process the Achievement's completion event;
3. update dependent achievements;
4. refresh the Profile Achievement UI;
5. broadcast the Achievement.

Loading an already-completed Profile must never re-trigger completion announcements.

---

# 12. Achievement Broadcasting

Achievement earning announcements are **normal visible chat messages**, not RPE addon synchronization messages.

Example:

```text
[RPE] Cybercog has earned the achievement [Boss Slayer]!
```

On completion:

```lua
if IsInGuild() then
    SendChatMessage(message, "GUILD")
end

if IsInRaid() then
    SendChatMessage(message, "RAID")
end
```

If the player is in both, the achievement is announced in both.

CrusadeToolkit currently has separate achievement update and achievement-earned broadcast concepts. RPE should preserve that separation:

```text
internal state/progress
≠
public achievement announcement
```

---

# 13. Profile → Achievements UI

The current Profile window has four tabs:

```text
Equipment & Stats
Spellbook
Traits
Skills
```

and routes tab construction and refresh through `window_Profile.lua`.

Add:

```text
Achievements
```

Proposed file:

```text
client/character/profile/page_ProfileAchievements.lua
```

and add:

```lua
achievementsPage = ProfileUI.AchievementsPage
```

to the Profile window instance.

The new tab is then added through the existing `UI.Window` tabs table and `RefreshTab()` pattern.

---

## 13.1 Achievement page layout

Recommended structure:

```text
┌──────────────────────────────────────────────────────┐
│ Equipment | Spellbook | Traits | Skills | Achievements
├───────────────┬──────────────────────────────────────┤
│ All           │ [icon] Boss Slayer                  │
│ Combat        │ Defeat 10 enemies in RPE events.    │
│ Events        │                                     │
│ Guild         │ █████████████░░░ 7 / 10             │
│ Other         │                                     │
│               │ [icon] First Blood                  │
│               │ Defeat an enemy during an RPE event │
│               │ Completed 23 Aug 2026               │
└───────────────┴──────────────────────────────────────┘
```

The implementation should use existing RPE UI abstractions:

```text
Panel
VerticalLayoutGroup
HorizontalLayoutGroup
ScrollLayout
ProgressBar
Text
Image
```

rather than Blizzard XML/templates or the custom CrusadeToolkit UI code.

Achievement tags can initially drive category/filter presentation without requiring a new explicit category field.

---

# 14. Achievement Authoring UI

Phase 1 should replace the existing placeholder Achievement Data Editor page with a functional list/grid.

The Achievement inspector should support:

```text
General
  Name
  Description
  Icon
  Tags

Criteria
  Add Criterion
  Criterion ID
  Description
  Trigger
  Goal
  Trigger-specific filters

Rewards
  Existing rewards field
```

Proposed file:

```text
client/ui/editor/inspectors/page_InspectorAchievement.lua
```

The existing Data Editor maps content collections to inspector pages, but currently does not map Achievements to an inspector.

That mapping must be added during Phase 1.

---

# 15. GuildSetting Dataset Class

Add:

```text
core/classes/GuildSetting.lua
```

following the normalization/serialization pattern used by current classes such as `Currency` and `Skill`.

Proposed structure:

```lua
GuildSetting {
    id = nil,
    name = "",
    description = "",

    guildName = "",

    general = {
        enableRequisitions = false,
        enableDailyRewards = false,
        enableProgression = false,
    },

    requisitions = {},

    dailyRewards = {},

    progression = {
        slotCount = 3,
        entries = {},
    },

    tags = {},
}
```

`guildName` may be blank.

A blank guild name means:

```text
This setting may apply to the player's current guild.
```

A populated guild name restricts the setting to that guild.

This allows generic reusable datasets while preventing guild-specific datasets from unintentionally configuring unrelated guilds.

---

# 16. Active GuildSetting Resolution

Introduce:

```lua
Guild:GetActiveGuildSetting()
```

Resolution rules:

```text
1. Player must currently be in a guild.

2. Search GuildSettings in activated datasets.

3. Exact guildName matches take priority.

4. If no exact match exists, an unbound GuildSetting may apply.

5. If multiple settings have equal priority:
      return a conflict state
      do not silently choose one.
```

The Guild window should display:

```text
Multiple active Guild Settings apply to this guild.
Disable one of the conflicting datasets.
```

rather than applying unpredictable configuration.

This uses the existing RPE concept of activated datasets through the Registry.

---

# 17. Requisition Definition

Inside `GuildSetting.requisitions`:

```lua
{
    id = "standard_rifle",

    itemRef = "gns:standard_rifle",
    quantity = 1,

    costs = {
        {
            currencyRef = "copper",
            amount = 50000,
        },
        {
            currencyRef = "gns:commendation",
            amount = 2,
        },
    },

    requiredGuildRankIndex = 3,

    characterLimit = 1,
}
```

`characterLimit` defaults to:

```text
1
```

and is a **lifetime per-character limit for that Requisition definition**.

A later feature can introduce reset policies if required, but Phase 2 should not implicitly make this daily or weekly.

---

# 18. Guild Rank Semantics

WoW guild rank indexes are inverse to normal numeric hierarchy:

```text
0 = highest rank
larger number = lower rank
```

GNS already implements the correct check:

```lua
playerRankIndex <= requiredRankIndex
```

RPE should use the same rule.

The Data Editor should present the field to the user as:

```text
Minimum Guild Rank
```

while persisting:

```lua
requiredGuildRankIndex
```

---

# 19. Requisition Transaction

Requisitioning must be handled by one central function, for example:

```lua
Guild:TryRequisition(guildSettingRef, requisitionId)
```

The UI must not perform the actual business logic itself.

Validation order:

```text
Guild feature enabled
        ↓
Player is in applicable guild
        ↓
Requisition exists
        ↓
Item reference resolves
        ↓
Player satisfies guild rank
        ↓
Character limit not reached
        ↓
All currencies resolve
        ↓
Player can afford every cost
        ↓
Commit transaction
```

Commit:

```text
Spend all required currencies
        ↓
Add item through Client.Inventory.AddItem()
        ↓
Increment requisition ledger
        ↓
Refresh Guild UI
```

All costs must be validated **before any currency is spent**.

If an unexpected failure occurs after spending begins, balances must be restored so a partial transaction cannot occur.

GNS provides useful precedent for visually locking acquisitions based on guild rank and available resources, but its UI directly gates item acquisition. In RPE, the UI state is only informative; the transaction function must independently repeat all checks.

---

# 20. Daily Reward Definition

Use one typed reward list:

```lua
dailyRewards = {
    {
        id = "ration",
        type = "item",
        ref = "campaign:field_ration",
        amount = 2,
    },

    {
        id = "allowance",
        type = "currency",
        ref = "campaign:commendation",
        amount = 1,
    },
}
```

This is preferable to separate item/currency lists because the GuildSetting editor can represent the daily reward as one ordered collection.

---

# 21. Daily Reward Processing

Daily rewards should be awarded automatically when an eligible character logs in.

The existing RPE Runtime centralizes Blizzard event registration and already receives `PLAYER_ENTERING_WORLD`.

Extend this runtime integration to also handle the guild lifecycle, including appropriate guild-roster/membership update events.

Processing should be:

```text
PLAYER_ENTERING_WORLD
        ↓
Guild context available?
        ↓ no
wait for guild roster/update event
        ↓ yes
Resolve GuildSetting
        ↓
Daily rewards enabled?
        ↓
Already claimed for current calendar day?
        ↓ no
Validate every reward definition
        ↓
Award rewards
        ↓
Record today's claim
```

The operation must be idempotent.

A `/reload` must not provide another reward.

---

# 22. Daily Reward Day Key

Store a stable server/calendar day key such as:

```text
2026-08-23
```

Do **not** implement this as:

```text
lastRewardTimestamp + 86400
```

because the requirement is one reward per calendar day, not one reward every rolling 24 hours.

---

# 23. Guild Profile State

Guild state should support characters changing guilds.

Proposed structure:

```lua
profile.guild = {
    byGuild = {
        ["guild-key"] = {
            dailyRewardDate = nil,

            requisitions = {
                ["dataset:guildSetting"] = {
                    ["standard_rifle"] = 1,
                },
            },

            progression = {
                ["dataset:guildSetting"] = {
                    ...
                },
            },
        },
    },
}
```

The `guild-key` should be produced by one Guild helper from the best stable Blizzard guild identity available, with guild name/realm as fallback.

This avoids one guild's daily-reward/requisition history leaking into another guild if the character changes guilds.

---

# 24. Guild Window

Create a new top-level window rather than embedding guild functionality inside Profile.

Proposed namespace:

```lua
Addon.Client.UI.Guild
```

Proposed files:

```text
client/character/guild/page_GuildRequisitions.lua
client/character/guild/page_GuildProgression.lua
client/character/guild/page_GuildAdmin.lua
client/character/guild/window_Guild.lua
```

Tabs:

```text
Requisitions
Progression
Admin
```

Use the same `UI.Window` tab architecture already used by the Profile window.

---

# 25. Launcher and Slash Command Integration

The current Launcher has Profile, Event and Settings groups, and routes destinations through `Client:Open...LauncherDestination()` functions.

Add:

```text
Guild
```

to the Launcher.

Also add:

```text
/rpe guild
```

through the same command registration system currently used by `/rpe profile`, `/rpe inventory`, `/rpe data`, etc.

---

# 26. Requisitions Tab UI

The first section displays Daily Rewards:

```text
DAILY REWARD

[icon] Field Ration ×2
[icon] Guild Commendation ×1

Received today
```

or:

```text
Daily rewards are disabled for this guild.
```

The second section lists Requisitions:

```text
[ITEM ICON] Standard Rifle

Cost
  50,000 Copper
  2 Guild Commendations

Minimum Rank
  Militant

Character Limit
  0 / 1

[ Requisition ]
```

Unavailable buttons must explain why:

```text
Requires rank: Knight
Insufficient Guild Commendations
Character limit reached
Requisitions disabled
```

Do not rely solely on desaturation.

---

# 27. Guild Administration

The Admin tab allows guild officers to modify an **online RPE member's own character state**.

Required operations:

```text
Grant Achievement
Increase Skill
Decrease Skill
Give Item
```

The tab should use the live WoW guild roster for member discovery.

CrusadeToolkit's Guild Admin page already demonstrates the basic interaction pattern of:

```text
Guild roster
   ↓
rank ordering
   ↓
select member
   ↓
member editor
```

RPE should reuse the product interaction, not CrusadeToolkit's storage implementation.

---

# 28. Important Constraint: Profiles Cannot Be Directly Edited Remotely

Another player's:

```text
RPEngineProfilesDB
RPEngineInventoryDB
```

exist on **their** WoW client.

An officer therefore cannot directly write them.

Guild administration must work as:

```text
Officer RPE client
        │
        │ targeted RPE addon message
        ▼
Member RPE client
        │
        ├─ validate officer
        ├─ validate operation
        ├─ mutate local data
        └─ send response
        │
        ▼
Officer RPE client
```

Only online members running a compatible RPE version can therefore be administrated.

Offline Profile modification is out of scope.

---

# 29. Guild Admin Communications

Extend the existing RPE Operations table rather than introducing another addon prefix.

At the inspected code state, opcodes 1–23 are in use.

Allocate the next available operation IDs when implementation begins, conceptually:

```text
GUILD_ADMIN_QUERY
GUILD_ADMIN_QUERY_RESPONSE
GUILD_ADMIN_MUTATION
GUILD_ADMIN_MUTATION_RESPONSE
```

These can be four opcodes or two request/response opcodes with an operation discriminator.

Recommended mutation envelope:

```lua
{
    requestId = "...",
    protocolVersion = 1,

    operation = "give_item",

    data = {
        itemRef = "campaign:standard_rifle",
        quantity = 1,
    },
}
```

The sender identity must come from the addon-message transport, not from a client-supplied `sender` field.

---

# 30. Guild Admin Member Query

When the officer selects an online member, RPE should request the minimal state required by the Admin UI.

Response:

```lua
{
    achievements = {
        ["campaign:first_blood"] = {
            completedAt = 1787481200,
        },
    },

    skills = {
        ["core:athletics"] = 12,
        ["core:medicine"] = 8,
    },
}
```

Inventory contents do not need to be transmitted merely to give an item.

This allows the officer UI to show:

```text
Achievements
  First Blood                Earned
  Boss Slayer                [Grant]

Skills
  Athletics                   12  [-] [+]

Items
  [Select Item] [Quantity] [Give]
```

---

# 31. Receiver-Side Guild Admin Validation

Every incoming administrative mutation must independently verify:

```text
Sender is in the same guild
Sender currently has an officer-capable guild rank
Requested operation is supported
Referenced Dataset object exists
Numeric values are valid
Target is this client's own active character
```

The recipient must never trust:

```lua
payload.isOfficer = true
```

or any equivalent client-supplied permission value.

The Admin UI itself should also be inaccessible/locked to non-officers, but **UI gating is not security**.

---

# 32. Guild Admin Mutation Paths

## Grant Achievement

Use the Achievement runtime:

```lua
Achievements:Grant(achievementRef, {
    source = "guild_admin",
    actor = sender,
})
```

Do not directly modify:

```lua
profile.achievements
```

because normal completion handling must still run.

---

## Adjust Skill

Use:

```lua
local current = Profile.GetSkillLevel(skillRef)
Profile.SetSkillLevel(skillRef, current + delta)
```

after validating the Skill reference.

---

## Give Item

Resolve:

```lua
Registry:ResolveItemReference(itemRef)
```

then call:

```lua
Client.Inventory.AddItem({
    dataset = dataset.id,
    id = item.id,
    quantity = quantity,
})
```

This preserves RPE's existing stack and bind behavior.

---

# 33. Guild Admin Responses

Every mutation returns:

```lua
{
    requestId = "...",
    success = true,
    operation = "give_item",
}
```

or:

```lua
{
    requestId = "...",
    success = false,
    reason = "sender-not-officer",
}
```

Useful error codes include:

```text
target-offline / no response
sender-not-in-guild
sender-not-officer
unknown-achievement
unknown-skill
unknown-item
invalid-quantity
incompatible-protocol
```

The officer UI must not optimistically display success before acknowledgement.

---

# 34. Guild Progression

CrusadeToolkit's `CrusaderPath` is not simply an XP bar.

Its core model consists of progression panels containing:

- a named progression identity;
- descriptive/oath text;
- locked text;
- an unlocked state;
- a configured selection of abilities;
- a player's selected ability.

The character stores selected progression panels, unlock flags and selected spells.

RPE 2 should generalize this mechanism without embedding Holy Order-specific concepts.

---

# 35. GuildSetting Progression Definition

Proposed Phase 4 data:

```lua
progression = {
    slotCount = 3,

    entries = {
        {
            id = "aspirant",
            name = "Aspirant",
            description = "...",
            icon = "...",

            lockedText = "You have not yet unlocked this progression.",

            spellRefs = {
                "campaign:ability_one",
                "campaign:ability_two",
                "campaign:ability_three",
            },
        },

        {
            id = "knight",
            name = "Knight",
            description = "...",
            icon = "...",

            lockedText = "...",

            spellRefs = {
                ...
            },
        },
    },
}
```

`slotCount = 3` preserves CrusadeToolkit's existing three-panel behaviour as the default while allowing another GuildSetting to configure a different number.

There should be no hard-coded concepts such as:

```text
Squire
Aspirant
Knight
Crusader
Oath
Troth
```

in RPE core.

Those belong entirely to Dataset content.

---

# 36. Character Progression State

Example:

```lua
profile.guild.byGuild[guildKey].progression[guildSettingRef] = {
    slots = {
        [1] = "aspirant",
        [2] = "knight",
        [3] = "crusader",
    },

    unlocked = {
        ["aspirant"] = true,
        ["knight"] = true,
        ["crusader"] = false,
    },

    selectedSpells = {
        ["aspirant"] = "campaign:ability_one",
        ["knight"] = "campaign:ability_two",
    },
}
```

The Profile stores only IDs/references and state.

Names, descriptions, icons and available spell choices remain in the GuildSetting dataset.

---

# 37. Progression UI

The Progression tab should retain the core visual model from CrusadeToolkit:

```text
┌────────────────┐ ┌────────────────┐ ┌────────────────┐
│    ASPIRANT    │ │     KNIGHT     │ │    CRUSADER    │
│                │ │                │ │                │
│    [ICON]      │ │    [ICON]      │ │    [LOCK]      │
│                │ │                │ │                │
│ Description    │ │ Description    │ │ Requirements / │
│                │ │                │ │ locked text    │
│ [chosen power] │ │ [chosen power] │ │                │
└────────────────┘ └────────────────┘ └────────────────┘
```

RPE UI primitives should replace CrusadeToolkit's standalone frame construction.

Where more progression slots exist than fit horizontally, the page should paginate/scroll rather than assuming exactly three definitions exist.

---

# 38. Progression Administration

Phase 4 should extend the Guild Admin member editor with:

```text
Progression
```

allowing an officer to:

- assign an entry to a progression slot;
- lock/unlock an entry;
- clear a player's selected spell if necessary.

This reproduces the functional relationship between CrusadeToolkit's GuildAdmin and CrusaderPath without maintaining a second guild-member database.

The changes are applied remotely through the same Guild Admin communication protocol.

---

# 39. Dataset Dependency Integration

This is required and should not be omitted.

RPE's dependency system explicitly walks known fields in Units, Items, Traits, Skills, Spells, Auras and other definitions to determine cross-dataset dependencies.

It does **not currently inspect Achievement criteria**, and GuildSetting does not yet exist.

Phase 1 must add dependency extraction for:

### Achievement

```text
achievementRef
currencyRef
unitRef
and any other criterion reference
```

### GuildSetting

```text
Requisition itemRef
Requisition currencyRefs
Daily Reward item/currency refs
Progression spellRefs
Achievement refs used by future progression requirements
```

This is necessary so dataset activation/import/dependency handling remains correct when a GuildSetting references entries defined elsewhere.

Any reference-rewrite/pruning paths in `Dependecies.lua` must be extended at the same time.

---

# 40. Registry Additions

Add:

```lua
Registry:ResolveAchievementReference(achievementRef)
Registry:ResolveAchievementName(achievementRef)

Registry:ResolveGuildSettingReference(guildSettingRef)
```

using the same internal collection-cache mechanism already used for Items, Skills, Stats and other dataset entries.

This prevents individual systems from repeatedly hand-parsing:

```text
datasetId:id
```

---

# 41. Data Editor Integration

`GuildSetting` should become a normal dataset collection:

```text
guildSettings
```

Changes include:

```text
Database.DATASET_ENTRY_DEFINITIONS
normalizeDatasetRecord()
DataEditor ENTRY_DEFINITIONS
Data Editor page definitions
Data Editor refresh mapping
Inspector mapping
Dataset item-count display
Dependency handling
```

Proposed UI files:

```text
client/ui/editor/pages/page_GuildSetting.lua
client/ui/editor/inspectors/page_InspectorGuildSetting.lua
```

The page should expose:

```text
General
Requisitions
Daily Rewards
Progression
```

The Progression editing controls may initially be structural in Phase 1 and receive their complete behavior/editor polish in Phase 4.

---

# 42. Schema Changes

Current RPE database schemas include separate Profile and Dataset versions.

Proposed:

```text
Profile schema
4 → 5

Dataset schema
14 → 15
```

Profile normalization must add:

```lua
achievements = {}
guild = {}
```

Dataset normalization must add:

```lua
guildSettings = {}
```

Existing characters therefore migrate additively:

```text
old Profile
    ↓ normalization
old Profile + empty achievements + empty guild state
```

No destructive conversion is required.

Any default-profile detection/migration logic in `Database.lua` must also recognize these new fields.

---

# 43. Runtime Event Integration

RPE currently centralizes WoW runtime events in:

```text
core/internal/Runtime.lua
```

rather than giving every module an independent event frame.

Extend the same dispatcher for Guild functionality.

Relevant events should include the appropriate equivalents of:

```text
PLAYER_ENTERING_WORLD
guild membership update
guild roster update
```

and route them to:

```lua
Client.Guild:HandleRuntimeEvent(...)
```

or equivalent.

This is used for:

- resolving current guild state;
- refreshing the Admin roster;
- retrying Daily Reward processing when guild information becomes available.

---

# 44. Proposed Module Layout

```text
core/
  classes/
    Achievement.lua                 [modify]
    GuildSetting.lua                [new]

  internal/
    database/
      Database.lua                  [modify]
      Dependecies.lua               [modify]

    profile/
      Profile.lua                   [modify wrappers]
      Currencies.lua                [currency trigger hook]
      Achievements.lua              [new profile-state helpers]
      Guild.lua                     [new guild-state helpers]

    Registry.lua                    [modify]
    Runtime.lua                     [modify]
    comms/
      Operations.lua                [Phase 3 admin operations]

client/
  client_Achievements.lua           [new]
  client_Guild.lua                  [new]

  client_Resources.lua              [authoritative kill hook]
  client_Commands.lua               [guild command]

  character/
    profile/
      page_ProfileAchievements.lua  [new]
      window_Profile.lua             [modify]

    guild/
      page_GuildRequisitions.lua    [new]
      page_GuildProgression.lua     [new]
      page_GuildAdmin.lua           [new]
      window_Guild.lua              [new]

  ui/
    windows/
      window_LauncherMenu.lua       [modify]

    editor/
      pages/
        page_Achievement.lua        [complete]
        page_GuildSetting.lua       [new]

      inspectors/
        page_InspectorAchievement.lua
        page_InspectorGuildSetting.lua

      windows/
        window_DataEditor.lua       [modify]

RPEngine_Dev.toc                    [modify]
```

Exact naming can follow implementation preference, but responsibilities should remain separated this way.

---

# 45. Phase 1 — UI and Data Layer

## Data

Implement:

- normalized Achievement criteria schema;
- stable criterion IDs;
- `GuildSetting` class;
- `guildSettings` dataset collection;
- `profile.achievements`;
- `profile.guild`;
- Profile schema update;
- Dataset schema update;
- Registry Achievement/GuildSetting resolvers;
- Dependency discovery/rewrite support.

## Character UI

Implement:

- Profile → Achievements tab;
- empty/read-only Achievement presentation;
- Guild window;
- Requisitions page shell;
- Progression page shell;
- Admin page shell;
- guild roster display;
- officer access state.

## Data Editor

Implement:

- functional Achievement list/grid;
- Achievement inspector;
- Achievement criteria editor;
- GuildSetting page;
- GuildSetting inspector;
- Requisition definitions;
- Daily reward definitions;
- Progression definitions.

## Navigation

Implement:

```text
Launcher → Guild
/rpe guild
```

## Acceptance Criteria

Phase 1 is complete when:

```text
Existing Profiles load without errors.

Achievement/Guild Profile state survives /reload.

GuildSetting exports and imports as part of a Dataset.

Cross-dataset GuildSetting references create dependencies.

Achievements can actually be authored in the Data Editor.

Achievements appear in the Profile page even though automatic
progression is not active yet.

Guild window opens with all three tabs.

Guild roster is shown in Admin.

Normal members cannot use Admin controls.

No active GuildSetting produces a clean empty state.

Conflicting GuildSettings produce a clear error state.
```

---

# 46. Phase 2 — Guild Requisitions and Daily Rewards

Implement:

- active GuildSetting resolution;
- Requisition eligibility;
- rank gating;
- arbitrary RPE currency costs;
- multiple currency costs;
- per-character lifetime limits;
- transactional purchase handling;
- item grants through Inventory;
- Daily Reward validation;
- item rewards;
- currency rewards;
- daily claim ledger;
- runtime login/guild event integration;
- Requisitions UI refresh.

## Acceptance Criteria

A player cannot:

```text
requisition while the feature is disabled;

requisition while outside the configured guild;

requisition below the required guild rank;

requisition without sufficient currency;

exceed the per-character limit;

receive the daily reward twice through /reload;

receive a partial requisition after a failed transaction.
```

Successful claims persist across relogging.

Built-in and dataset-defined currencies both work.

---

# 47. Phase 3 — Achievements and Guild Administration

Implement the Achievement runtime.

Initial automatic triggers:

```text
currency_gain
rpe_kill
rpe_event_complete
achievement_earned
```

Implement:

- criterion trigger index;
- Profile progress mutation;
- completion evaluation;
- meta/dependency completion;
- completion timestamps;
- Profile UI progress display;
- visible Guild achievement announcements;
- visible Raid achievement announcements.

Then activate Guild Admin:

```text
member query
grant Achievement
increase/decrease Skill
give Item
request acknowledgement
receiver permission validation
```

Add required RPE Comms operations.

## Acceptance Criteria

```text
Currency gains update the correct criterion by the actual amount gained.

Currency spending does not count as earning currency.

A lethal preview does not award a kill.

Only an authoritative alive → dead RPE event transition awards a kill.

The kill is credited only to the correct local player.

Repeated updates to a dead EventUnit do not produce extra kills.

Completed achievements survive relogging.

Completed achievements are not announced again at login.

Meta achievements complete correctly.

Achievements announce to Guild when appropriate.

Achievements announce to Raid when appropriate.

A normal guild member cannot perform an Admin mutation merely by
calling the underlying message function.

Invalid Skill/Achievement/Item references are rejected.

An officer receives explicit success/failure acknowledgement.

Item administration goes through RPE Inventory.

Skill administration goes through RPE Profile APIs.
```

---

# 48. Phase 4 — Guild Progression

Implement:

- progression slot definitions;
- progression entries;
- unlocked/locked state;
- narrative/locked text;
- spell selections;
- persisted character progression state;
- Progression UI;
- officer progression administration;
- remote progression mutations through Guild Admin.

Optional automatic requirements can reuse the Achievement trigger/criteria infrastructure rather than introducing another event framework.

## Acceptance Criteria

```text
Progression state survives /reload.

Dataset content controls names, descriptions and choices.

Core contains no CrusadeToolkit-specific rank/oath terminology.

Locked entries cannot be selected.

Selected spells must be present in the configured entry.

Officer changes are validated by the target client.

Different GuildSettings can define completely different progression trees.

The default three-panel presentation reproduces the useful behaviour of
CrusadeToolkit without imposing a three-entry data limit.
```

---

# 49. Explicit Non-Goals

This project does not implement:

```text
Bestiary
Quest Log
CrusadeToolkit quest synchronization
CrusadeToolkit guild-member SavedVariables database
GNS standalone dashboard framework
Offline member editing
Native Blizzard Achievements
Generic arbitrary Profile-field editing
Arbitrary executable Lua contained in dataset criteria
A cryptographically secure character database
```

RPE SavedVariables remain fundamentally player-controlled.

---

# 50. Principal Architectural Decisions

**Achievement definitions remain Dataset data; progress remains Profile data.**

**Existing `Achievement.criteria` becomes the central progression model instead of importing CrusadeToolkit's top-level single/counter/checklist/meta state model.**

**All RPE object references use existing dataset-qualified references.**

**GuildSettings become normal dataset entries and participate in RPE dependency analysis.**

**Items remain in `RPEngineInventoryDB`; Guild systems use `Client.Inventory.AddItem()`.**

**Currencies use the existing Profile currency APIs.**

**Skills use the existing Profile skill APIs.**

**Currency Achievements trigger from `Profile.AddCurrencyAmount()`, not arbitrary currency assignment.**

**RPE kill Achievements trigger from the authoritative resource-delta alive→dead transition, not the preliminary damage preview.**

**Guild Admin extends RPE's existing Comms opcode system and uses targeted addon whispers.**

**The member's own client validates and applies every officer mutation.**

**Daily rewards are calendar-day based and idempotent.**

**Requisition validation exists in the transaction layer, not merely the UI.**

**CrusadeToolkit's progression panel/unlock/ability-choice behaviour is generalized into Dataset-driven Guild progression rather than copied with its campaign-specific terminology.**

This fits the new functionality into RPE 2's current architecture without creating parallel storage, UI, messaging, currency, inventory or event systems.
