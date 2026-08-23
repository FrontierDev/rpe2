# RPE 2 — Achievements and Guild Systems
## Product Design Document

**Status:** Revised after Phase 1  
**Target:** RPEngine 2.0 (`FrontierDev/rpe2`)  
**Scope:** Achievements, RPE Guild Ranks, Guild Requisitions, Daily Rewards, Guild Administration, Guild Progression  
**Reference addons:** `old_crusadetoolkit`, `gns_mekkatorque`  
**Explicitly out of scope:** Bestiary, Quest Log

## Revision note — Guild Rank model

The original design treated a `GuildSetting` as one active guild-wide configuration. That model is superseded.

From this revision onward:

- the existing internal `GuildSetting` class and `guildSettings` dataset collection are retained for compatibility;
- the concept is exposed to users as **Guild Rank**;
- a guild may define multiple RPE Guild Ranks;
- one WoW guild rank may map to multiple RPE Guild Ranks;
- a character has at most one assigned RPE Guild Rank within a guild at a time;
- the RPE Guild Rank is assigned manually by a guild officer;
- RPE never automatically derives, changes or clears a character's assigned RPE Guild Rank from their WoW guild rank;
- the WoW guild rank mapping constrains which RPE Guild Ranks an officer may assign;
- each RPE Guild Rank owns the Requisitions, Daily Rewards and Progression available while that rank is assigned;
- multiple RPE Guild Ranks applying to the same WoW guild rank are intentional and are not a configuration conflict;
- there is no implicit RPE Guild Rank hierarchy or inheritance. If content should be shared between ranks, the dataset must define it for each relevant rank unless a future inheritance feature is deliberately added.

Where this document refers to `GuildSetting`, it is referring to the current internal class/storage name. User-facing terminology is **Guild Rank**.

---

# 1. Purpose

This project extends RPE 2 with two related systems:

1. **Achievements**
   - Defined as dataset content.
   - Progress and completion stored per character Profile.
   - Displayed in Profile → Achievements.
   - Can progress automatically from RPE gameplay.
   - Can be granted manually by guild officers.
   - Newly earned achievements can be announced to Guild and Raid chat.

2. **Guild Systems**
   - A top-level RPE **Guild** window.
   - Dataset-defined RPE Guild Ranks.
   - Manual officer assignment of an RPE Guild Rank to an online member.
   - Rank-scoped Requisitions.
   - Rank-scoped Daily Rewards.
   - Rank-scoped Guild Progression.
   - Officer administration of online members' RPE characters.

The implementation must build on RPE 2's existing Database, Profile, Registry, Inventory, Runtime, UI and Comms systems rather than importing the architecture of either reference addon.

---

# 2. Existing RPE 2 Architecture

Phase 1 has established the data and read-only UI foundation required by this document.

## 2.1 Achievements are dataset objects

RPE 2 defines:

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

Achievement criteria are normalized, use stable criterion IDs and are authorable through the Data Editor.

Achievements are a first-class dataset collection and have a read-only Profile page backed by character Profile state.

---

## 2.2 Profiles are centrally normalized in Database.lua

RPE character Profiles contain state such as:

- race/class;
- equipment;
- spellbook;
- traits;
- skill levels;
- action bars;
- stat bonuses;
- currencies;
- Achievement state;
- Guild state.

Profile creation and normalization remain centralized in:

```text
core/internal/database/Database.lua
```

Guild Rank assignment must therefore extend the existing `profile.guild` state rather than introduce another SavedVariable.

---

## 2.3 Inventory is not part of the Profile

RPE character inventory is stored independently in:

```text
RPEngineInventoryDB
```

The canonical item award path is:

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

RPE supports built-in currencies:

```text
copper
valor
justice
honor
conquest
```

and dataset currencies:

```text
datasetId:currencyId
```

The Profile system exposes:

```lua
Profile.GetCurrencyAmount(...)
Profile.SetCurrencyAmount(...)
Profile.AddCurrencyAmount(...)
Profile.SpendCurrencyAmount(...)
Profile.ResolveCurrencyDefinition(...)
```

including caps and support for both built-in and dataset-defined currencies.

Guild Requisition costs therefore store currency references.

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

Guild Admin should modify skills through these APIs.

---

## 2.6 Dataset-qualified references are the RPE convention

The Registry consistently resolves entries using:

```text
datasetId:entryId
```

The current internal Guild Rank reference remains:

```text
datasetId:guildSettingId
```

For example:

```text
campaign:militant
campaign:medic
campaign:engineer
```

The field may be named `guildSettingRef` internally where existing APIs require it, but new Profile/runtime APIs should prefer the semantic name `guildRankRef` when no compatibility constraint requires otherwise.

All references from Guild Rank definitions to Items, Currencies, Spells or Achievements use the existing qualified-reference format.

---

## 2.7 RPE already has the communications infrastructure needed for Guild Admin

RPE has a central addon messaging layer with:

- registered opcodes;
- serialization;
- chunking;
- dispatch;
- channel messages;
- targeted addon messages;
- request/response operations.

Guild Administration must extend this protocol and use targeted `WHISPER` addon messages rather than creating another messaging subsystem.

---

# 3. Core Design Principle

The architecture maintains a strict distinction:

```text
Dataset / Definition                 Character State
──────────────────────────           ─────────────────────────────
Achievement definition         ->    Achievement progress
RPE Guild Rank (GuildSetting)  ->    Assigned Guild Rank ref
                                     Requisition usage
                                     Daily reward claim
                                     Progression state
```

A Dataset describes **what exists and what is available at a rank**.

A Profile describes **what this character has done and which RPE Guild Rank an officer has assigned**.

No player-specific assignment, completion, claim or progression state is serialized into an Achievement or Guild Rank dataset object.

The player's WoW guild rank is live Blizzard state. It is used to validate which RPE Guild Ranks may be assigned, but it is not the stored RPE Guild Rank.

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

RPE 2 instead models independently describable Achievement criteria. This allows those behaviours to emerge from one model without another top-level Achievement type.

---

# 5. Achievement Criteria Schema

An Achievement remains:

```lua
Achievement {
    id = "boss_slayer",
    name = "Boss Slayer",
    description = "Defeat ten enemies during RPE events.",
    icon = "...",
    criteria = { ... },
    rewards = {},
    tags = {},
}
```

Each criterion is normalized to:

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

Every criterion has a stable ID. Profile progress is keyed by criterion ID rather than array position.

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

This replaces CrusadeToolkit's name-based dependency system with stable RPE references.

---

# 6. Initial Achievement Trigger Types

The initial runtime trigger contract is:

```text
manual
currency_gain
rpe_kill
rpe_event_complete
achievement_earned
```

Likely future triggers include:

```text
item_gain
skill_gain
rpe_boss_kill
rpe_damage
rpe_healing
rpe_event_started
```

but they are not required for the initial Achievement runtime.

---

# 7. Achievement Profile State

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

A separate `completed = true` field is unnecessary because:

```lua
completedAt ~= nil
```

is sufficient.

---

# 8. Achievement Runtime

Introduce:

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

The runtime builds its index from:

```lua
Registry:GetActivatedDatasets()
```

rather than scanning every Achievement for every event.

---

# 9. Currency Gain Trigger

The correct integration point is:

```lua
Profile.AddCurrencyAmount(...)
```

not `SetCurrencyAmount()`, because absolute assignment may represent administrative changes or decreases.

`AddCurrencyAmount()` should calculate the actual applied increase after caps:

```lua
previousAmount
updatedAmount
actualGain = updatedAmount - previousAmount
```

and trigger only a positive applied gain.

---

# 10. RPE Kill Trigger

Achievements must not be awarded from preliminary Damage preview state.

Only the authoritative resource-delta path should detect:

```text
alive before delta
        ↓
authoritative RESOURCE_DELTA
        ↓
dead after delta
```

and generate `rpe_kill`.

Further updates to an already-dead EventUnit must not generate additional kills.

---

# 11. Achievement Completion

An Achievement completes when all criteria are satisfied.

Completion is transition-based:

```text
not complete
    ↓
complete
```

Only that transition should:

1. set `completedAt`;
2. process the completion event;
3. update dependent/meta achievements;
4. refresh Profile UI;
5. broadcast the Achievement.

Loading an already-completed Profile must never re-trigger completion behavior.

---

# 12. Achievement Broadcasting

Achievement announcements are visible chat messages, not RPE synchronization messages.

Example:

```text
[RPE] Cybercog has earned the achievement [Boss Slayer]!
```

On completion, Guild and Raid messages may be emitted when appropriate.

Internal progress synchronization and public chat announcements remain separate concerns.

---

# 13. Profile → Achievements UI

The Profile window includes an `Achievements` tab using the existing RPE UI architecture.

The page displays:

- Achievement icon;
- name;
- description;
- tag-based filters;
- criterion progress;
- complete/incomplete state;
- completion date.

Viewing the page must never mutate Achievement progress.

---

# 14. Achievement Authoring UI

The Data Editor supports Achievement authoring through the normal dataset editor.

The inspector exposes:

```text
General
  Name
  Description
  Icon
  Tags

Criteria
  Add/Delete Criterion
  Criterion ID
  Description
  Trigger
  Goal
  Trigger-specific filters

Rewards
  Existing opaque rewards field
```

Criterion edits must preserve IDs of unaffected criteria.

---

# 15. RPE Guild Rank Dataset Model

The existing internal class remains:

```text
core/classes/GuildSetting.lua
```

and the existing dataset collection remains:

```text
guildSettings
```

for compatibility with already-authored datasets and Phase 1 code.

**All user-facing labels must call these entries `Guild Rank`.**

The revised internal structure is:

```lua
GuildSetting {
    id = nil,
    name = "",
    description = "",

    guildName = "",

    wowGuildRankIndices = {},

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

`wowGuildRankIndices` is a normalized, deduplicated array of non-negative Blizzard guild rank indexes.

An empty array means the RPE Guild Rank is not restricted to a particular WoW guild rank and may be assigned to any member of the applicable guild.

A populated `guildName` restricts the RPE Guild Rank to that guild. A blank `guildName` defines a generic reusable rank.

The existing `requiredGuildRankIndex` field inside Requisition definitions is superseded by the rank-scoped model. It may be preserved temporarily during backward-compatible normalization/import, but new UI and runtime behavior must not depend on it.

---

# 16. Applicable Guild Rank Catalogue

The old single-setting function concept:

```lua
Guild:GetActiveGuildSetting()
```

is superseded by a Guild Rank catalogue.

Recommended facade operations:

```lua
Guild:GetApplicableGuildRanks()
Guild:GetEligibleGuildRanksForWoWRank(wowRankIndex)
Guild:GetAssignedGuildRankRef()
Guild:GetAssignedGuildRank()
```

Catalogue resolution rules:

```text
1. Player must currently be in a guild.

2. Search Guild Rank definitions (`guildSettings`) in activated datasets.

3. Collect exact guildName matches.

4. If at least one exact guildName match exists, use the full exact-match set.

5. Otherwise use the full set of blank/generic guildName definitions.

6. Multiple definitions in the selected set are expected and are not a conflict.
```

A rank's stable identity remains its qualified dataset reference:

```text
datasetId:guildSettingId
```

No first-match selection is performed.

---

# 17. WoW Guild Rank Mapping Semantics

WoW guild rank indexes remain inverse to normal numeric hierarchy:

```text
0 = highest WoW guild rank
larger number = lower WoW guild rank
```

However, RPE Guild Ranks are **not automatically derived from this hierarchy**.

The mapping is a set-membership constraint.

Example:

```lua
GuildSetting {
    id = "militant",
    wowGuildRankIndices = { 4 },
}

GuildSetting {
    id = "medic",
    wowGuildRankIndices = { 4 },
}

GuildSetting {
    id = "engineer",
    wowGuildRankIndices = { 4 },
}
```

A member whose WoW guild rank index is `4` may therefore be assigned any of:

```text
Militant
Medic
Engineer
```

by an officer.

This is the required many-RPE-ranks-per-WoW-rank relationship.

There is no implicit rule such as:

```lua
playerRankIndex <= requiredRankIndex
```

for selecting an RPE Guild Rank. That comparison remains useful only for unrelated WoW-rank permission concepts if explicitly needed elsewhere.

---

# 18. Manual RPE Guild Rank Assignment

A player's RPE Guild Rank is stored in Profile state and is set manually by a guild officer.

Example:

```lua
profile.guild.byGuild[guildKey] = {
    assignedRankRef = "campaign:medic",
    assignedRankAt = 1787481200,
    assignedRankBy = "Officer-Realm",
}
```

The assignment flow is:

```text
Officer selects online guild member
        ↓
RPE shows RPE Guild Ranks eligible for that member's current WoW guild rank
        ↓
Officer selects one RPE Guild Rank, or clears the assignment
        ↓
targeted RPE addon message
        ↓
member client validates sender, guild, officer state and rank eligibility
        ↓
member client stores assignedRankRef in its own Profile
        ↓
member client acknowledges success/failure
```

RPE must never automatically assign a rank because:

- the player logged in;
- the player joined the guild;
- the player's WoW guild rank changed;
- only one eligible RPE rank exists;
- a dataset was activated.

If an existing assignment becomes invalid because the member's WoW guild rank changed or the referenced RPE Guild Rank is no longer applicable, RPE should treat it as an **invalid assignment** for feature eligibility and show an explanatory UI state. It must not silently remap or clear the Profile value.

No assigned RPE Guild Rank means no rank-scoped Requisitions, Daily Rewards or Progression are available.

WoW officer permission remains the authority for Guild Admin access. Being assigned a particular RPE Guild Rank does not itself make a user an officer.

---

# 19. Requisition Definition

Requisitions live inside the RPE Guild Rank that grants access to them:

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

    characterLimit = 1,
}
```

There is no new per-Requisition minimum guild rank field. The enclosing RPE Guild Rank already defines who may see and use the Requisition.

`characterLimit` defaults to `1` and is a lifetime per-character limit for that Requisition definition within that RPE Guild Rank.

---

# 20. Requisition Transaction

Use one central function, for example:

```lua
Guild:TryRequisition(guildRankRef, requisitionId)
```

The UI must not perform the business logic.

Validation order:

```text
Player has a valid assigned RPE Guild Rank
        ↓
Assigned rank equals guildRankRef
        ↓
Requisitions enabled for that RPE Guild Rank
        ↓
Requisition exists in that RPE Guild Rank
        ↓
Item reference resolves
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
Increment rank-scoped requisition ledger
        ↓
Refresh Guild UI
```

All costs must be validated before any currency is spent. Partial transactions must roll back.

---

# 21. Daily Reward Definition

Daily Rewards live inside the assigned RPE Guild Rank:

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

The reward granted on a day is the reward list belonging to the character's valid assigned RPE Guild Rank at claim time.

---

# 22. Daily Reward Processing and Day Key

Daily rewards are awarded automatically only when a character has a valid officer-assigned RPE Guild Rank.

Processing:

```text
PLAYER_ENTERING_WORLD / guild context refresh
        ↓
Valid assigned RPE Guild Rank?
        ↓ no
stop without assigning one
        ↓ yes
Daily rewards enabled for assigned rank?
        ↓
Already claimed for current guild/calendar day?
        ↓ no
Validate every reward definition
        ↓
Award rewards
        ↓
Record today's claim and rankRef used
```

The calendar key should be stable, for example:

```text
2026-08-23
```

Do not use a rolling 24-hour timer.

A rank change after a daily reward has been claimed must **not** permit a second daily reward from the newly assigned rank on the same calendar day. The claim ledger is one claim per character, per guild, per calendar day.

Store the rank used for the claim for display/debugging, but do not key claim eligibility by rank.

---

# 23. Guild Profile State

Guild state supports characters changing guilds and changing RPE Guild Ranks.

Proposed structure:

```lua
profile.guild = {
    byGuild = {
        [guildKey] = {
            assignedRankRef = "campaign:medic",
            assignedRankAt = 1787481200,
            assignedRankBy = "Officer-Realm",

            dailyRewardDate = "2026-08-23",
            dailyRewardRankRef = "campaign:medic",

            requisitions = {
                ["campaign:medic"] = {
                    ["field_ration"] = 1,
                },
            },

            progression = {
                ["campaign:medic"] = {
                    ...
                },
            },
        },
    },
}
```

The guild key is produced by one Guild helper from the best stable Blizzard guild identity available, with guild name/realm fallback.

Requisition and progression state remain keyed by RPE Guild Rank reference so changing ranks does not erase previous rank-specific state. Returning to a prior rank restores its previous persisted state.

---

# 24. Guild Window

The top-level Guild window remains:

```text
Requisitions
Progression
Admin
```

The window should also show the local character's assigned RPE Guild Rank prominently, for example:

```text
Guild Rank: Medic
```

or:

```text
Guild Rank: Not assigned
```

or:

```text
Guild Rank: Medic (assignment no longer valid for current WoW rank)
```

Requisitions and Progression render from the assigned RPE Guild Rank only.

---

# 25. Launcher and Slash Command Integration

Keep:

```text
Launcher → Guild
/rpe guild
```

through the existing navigation system.

---

# 26. Requisitions Tab UI

The Requisitions tab renders only content from the valid assigned RPE Guild Rank.

Example:

```text
GUILD RANK
Medic

DAILY REWARD
[icon] Field Ration ×2
[icon] Guild Commendation ×1
Received today

REQUISITIONS
[ITEM ICON] Medical Satchel
Cost
  2 Guild Commendations
Character Limit
  0 / 1
[ Requisition ]
```

There is no `Minimum Rank` row because rank eligibility is represented by the assigned RPE Guild Rank itself.

Unavailable buttons must explain why, for example:

```text
No RPE Guild Rank assigned
Assigned RPE Guild Rank is no longer valid
Insufficient Guild Commendations
Character limit reached
Requisitions disabled for this Guild Rank
```

---

# 27. Guild Administration

The Admin tab allows WoW guild officers to modify an online RPE member's own character state.

Required operations become:

```text
Set/Clear RPE Guild Rank
Grant Achievement
Increase Skill
Decrease Skill
Give Item
```

The live WoW guild roster remains the member-discovery source.

Selecting a member should show both:

```text
WoW Guild Rank
RPE Guild Rank
```

The RPE Guild Rank selector presents all applicable RPE Guild Ranks whose `wowGuildRankIndices` contains the member's current WoW guild rank index, plus unrestricted ranks whose mapping list is empty.

Multiple eligible RPE Guild Ranks are expected.

---

# 28. Important Constraint: Profiles Cannot Be Directly Edited Remotely

Another player's:

```text
RPEngineProfilesDB
RPEngineInventoryDB
```

exist on their WoW client.

An officer therefore cannot directly write them.

Guild administration works as:

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

Only online members running a compatible RPE version can be administrated.

---

# 29. Guild Admin Communications

Extend the existing RPE Operations table rather than introducing another addon prefix.

Conceptual operations:

```text
GUILD_ADMIN_QUERY
GUILD_ADMIN_QUERY_RESPONSE
GUILD_ADMIN_MUTATION
GUILD_ADMIN_MUTATION_RESPONSE
```

The mutation discriminator includes:

```text
set_guild_rank
clear_guild_rank
grant_achievement
adjust_skill
give_item
```

Example rank mutation:

```lua
{
    requestId = "...",
    protocolVersion = 1,
    operation = "set_guild_rank",
    data = {
        guildRankRef = "campaign:medic",
    },
}
```

Sender identity comes from the addon-message transport, never a client-supplied sender field.

---

# 30. Guild Admin Member Query

When an officer selects an online member, query the minimal state required by Admin UI.

Response:

```lua
{
    assignedGuildRankRef = "campaign:medic",

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

The member's WoW guild rank is normally available from the guild roster and should not be trusted from a mutation payload.

Inventory contents do not need to be transmitted merely to give an item.

---

# 31. Receiver-Side Guild Admin Validation

Every incoming administrative mutation independently verifies:

```text
Sender is in the same guild
Sender currently has WoW officer capability
Requested operation is supported
Target is this client's own active character
Referenced Dataset object exists
Numeric values are valid
```

For `set_guild_rank`, additionally verify:

```text
RPE Guild Rank is in the current applicable guild catalogue
Target's live WoW guild rank index is allowed by that RPE Guild Rank
```

An empty `wowGuildRankIndices` list is unrestricted.

The recipient must never trust client-supplied values such as:

```lua
payload.isOfficer = true
payload.targetWowRankIndex = 4
```

The target client determines its own live guild/rank state.

---

# 32. Guild Admin Mutation Paths

## Set/Clear RPE Guild Rank

Use a Profile/Guild state helper such as:

```lua
Profile.SetAssignedGuildRank(guildKey, guildRankRef, metadata)
Profile.ClearAssignedGuildRank(guildKey)
```

Only the validated receiver-side Guild Admin operation should call this on behalf of another player.

Setting an RPE Guild Rank does not automatically award its Daily Reward, consume a Requisition or mutate Progression. Normal runtime/UI refresh follows the assignment change.

## Grant Achievement

Use the Achievement runtime:

```lua
Achievements:Grant(achievementRef, {
    source = "guild_admin",
    actor = sender,
})
```

## Adjust Skill

Use Profile skill APIs after reference validation.

## Give Item

Resolve through Registry and award through `Client.Inventory.AddItem()`.

---

# 33. Guild Admin Responses

Every mutation returns explicit acknowledgement:

```lua
{
    requestId = "...",
    success = true,
    operation = "set_guild_rank",
}
```

or:

```lua
{
    requestId = "...",
    success = false,
    reason = "rank-not-eligible",
}
```

Useful errors include:

```text
target-offline / no response
sender-not-in-guild
sender-not-officer
unknown-guild-rank
rank-not-applicable
rank-not-eligible
unknown-achievement
unknown-skill
unknown-item
invalid-quantity
incompatible-protocol
```

The officer UI must not display success before acknowledgement.

---

# 34. Guild Progression

CrusadeToolkit's progression concept remains useful as a generalized RPE system containing:

- a named progression identity;
- descriptive text;
- locked text;
- an unlocked state;
- configured ability choices;
- a player's selected ability.

The revised design scopes that progression to the assigned RPE Guild Rank.

---

# 35. RPE Guild Rank Progression Definition

Each RPE Guild Rank owns its own progression definition:

```lua
progression = {
    slotCount = 3,

    entries = {
        {
            id = "field_medicine",
            name = "Field Medicine",
            description = "...",
            icon = "...",
            lockedText = "You have not yet unlocked this progression.",
            spellRefs = {
                "campaign:ability_one",
                "campaign:ability_two",
            },
        },
    },
}
```

The progression entry is not itself the character's RPE Guild Rank. It is progression content available **inside** that Guild Rank.

There are no hard-coded campaign-specific rank/oath terms in RPE core.

---

# 36. Character Progression State

Example:

```lua
profile.guild.byGuild[guildKey].progression[guildRankRef] = {
    slots = {
        [1] = "field_medicine",
    },

    unlocked = {
        ["field_medicine"] = true,
    },

    selectedSpells = {
        ["field_medicine"] = "campaign:ability_one",
    },
}
```

Changing the assigned RPE Guild Rank does not delete progression state associated with the previous rank.

Only the currently assigned valid rank's progression is active/displayed.

---

# 37. Progression UI

The Progression tab renders the assigned rank's configured progression entries.

Where more slots exist than fit horizontally, the page paginates or scrolls rather than assuming exactly three definitions.

No progression from a different RPE Guild Rank is displayed as active.

---

# 38. Progression Administration

Guild Admin may later expose Progression controls for the selected member:

- assign an entry to a progression slot;
- lock/unlock an entry;
- clear a selected spell.

Every remote mutation is validated against the member's currently assigned RPE Guild Rank and its progression definition.

A rank assignment change does not destroy previous rank-scoped progression state.

---

# 39. Dataset Dependency Integration

Dependency extraction remains required for Achievement and internal `GuildSetting` definitions.

### Achievement

```text
achievementRef
currencyRef
unitRef
other defined criterion references
```

### RPE Guild Rank / GuildSetting

```text
Requisition itemRef
Requisition currencyRefs
Daily Reward item/currency refs
Progression spellRefs
future Achievement refs used by progression requirements
```

`wowGuildRankIndices` contains Blizzard numeric rank indexes and creates no dataset dependency.

`assignedRankRef` is Profile state, not Dataset definition data, so it is not part of dataset dependency discovery.

---

# 40. Registry Additions

Existing internal resolvers remain valid:

```lua
Registry:ResolveAchievementReference(achievementRef)
Registry:ResolveAchievementName(achievementRef)
Registry:ResolveGuildSettingReference(guildSettingRef)
```

A semantic alias may be added if useful:

```lua
Registry:ResolveGuildRankReference(guildRankRef)
```

but existing datasets and APIs must not be broken solely to rename the internal class.

---

# 41. Data Editor Integration

The internal collection remains:

```text
guildSettings
```

but Data Editor user-facing text becomes:

```text
Guild Ranks
Guild Rank
New Guild Rank
```

The editor exposes:

```text
General
  Name
  Description
  Guild Name
  Eligible WoW Guild Ranks
  Enable Requisitions
  Enable Daily Rewards
  Enable Progression
  Tags

Requisitions
Daily Rewards
Progression
```

`Eligible WoW Guild Ranks` edits `wowGuildRankIndices` and permits multiple RPE Guild Rank entries to contain the same WoW rank index.

The old Requisition-level `Minimum Guild Rank` control is removed from the user-facing editor because Requisitions are rank-scoped.

Existing datasets containing `requiredGuildRankIndex` must continue to import without crashing, but the field is legacy and does not participate in the new eligibility model.

---

# 42. Schema and Migration Changes

Phase 1 currently uses:

```text
Profile schema = 5
Dataset schema = 15
```

The Guild Rank revision should increment these additively:

```text
Profile schema
5 → 6

Dataset schema
15 → 16
```

Profile normalization adds/normalizes rank assignment fields inside each guild bucket without destroying existing requisition/progression/future nested fields.

Dataset normalization adds:

```lua
wowGuildRankIndices = {}
```

to each internal `GuildSetting`.

Existing `GuildSetting` records therefore become unrestricted RPE Guild Ranks until an author configures their WoW rank mappings.

Existing `requiredGuildRankIndex` values are legacy data. They should be preserved through compatibility normalization/import where practical but are not automatically converted into `wowGuildRankIndices`, because the old minimum-rank rule cannot reliably infer the author's intended new RPE Guild Rank assignments.

No automatic character rank assignment is performed during migration.

---

# 43. Runtime Event Integration

RPE continues to centralize WoW runtime events in:

```text
core/internal/Runtime.lua
```

Guild membership/roster events are used to:

- refresh the Guild Rank catalogue;
- refresh officer/member roster UI;
- revalidate whether the stored assignment is currently eligible;
- retry Daily Reward processing when guild information becomes available.

They must **not** assign, remap or clear `assignedRankRef` automatically.

---

# 44. Proposed Module Layout

Existing Phase 1 files remain the starting point:

```text
core/
  classes/
    Achievement.lua
    GuildSetting.lua                 [extend Guild Rank schema]

  internal/
    database/
      Database.lua                   [schema/profile/dataset migration]
      Dependecies.lua

    profile/
      Achievements.lua
      Guild.lua                      [assigned-rank state helpers]
      Currencies.lua
      Profile.lua

    Registry.lua                     [optional Guild Rank alias]
    Runtime.lua
    comms/
      Operations.lua                [Guild Admin operations]

client/
  client_Achievements.lua            [future Achievement runtime]
  client_Guild.lua                   [Guild Rank catalogue/eligibility/runtime]
  client_Resources.lua               [authoritative kill hook]
  client_Commands.lua

  character/
    profile/
      page_ProfileAchievements.lua
      window_Profile.lua

    guild/
      page_GuildRequisitions.lua
      page_GuildProgression.lua
      page_GuildAdmin.lua
      window_Guild.lua

  ui/
    windows/
      window_LauncherMenu.lua

    editor/
      pages/
        page_Achievement.lua
        page_GuildSetting.lua        [externally Guild Ranks]

      inspectors/
        page_InspectorAchievement.lua
        page_InspectorGuildSetting.lua

      windows/
        window_DataEditor.lua

RPEngine_Dev.toc
```

---

# 45. Phase 1 — UI and Data Layer — Complete Baseline

Phase 1 established:

- normalized Achievement criteria;
- stable criterion IDs;
- internal `GuildSetting` class and dataset collection;
- Profile Achievement/Guild state;
- Registry/dependency support;
- Achievement Data Editor authoring;
- GuildSetting Data Editor authoring;
- read-only Profile Achievements;
- read-only Guild Requisitions/Progression/Admin shell;
- guild roster display and WoW officer gating;
- Launcher and `/rpe guild` integration.

The Guild Rank revision builds on this baseline rather than restarting it.

---

# 46. Phase 2 — Guild Rank Revision, Requisitions and Daily Rewards

Before transactional Guild features are activated, refactor the Phase 1 Guild model to the revised RPE Guild Rank semantics.

Implement:

```text
External Guild Rank terminology
wowGuildRankIndices model/editor
Profile assignedRankRef state
Applicable Guild Rank catalogue
WoW-rank eligibility filtering
Manual officer rank assignment
Remote validation/acknowledgement
Assigned-rank Guild UI states
Rank-scoped Requisitions
Rank-scoped Daily Rewards
One daily claim per guild/calendar day
```

Acceptance includes:

```text
One WoW guild rank can offer multiple assignable RPE Guild Ranks.

No RPE Guild Rank is automatically assigned on login, guild join, WoW rank
change or dataset activation.

A non-officer cannot assign an RPE Guild Rank.

The target client rejects a rank not valid for its own live WoW guild rank.

No assigned rank produces a clean non-transactional empty state.

An invalid/stale assignment is surfaced and never silently remapped.

Only the assigned valid RPE Guild Rank contributes Requisitions and Daily
Rewards.

Changing rank after claiming a Daily Reward does not grant a second reward
on the same calendar day.

Requisition transactions remain atomic and use existing Currency/Inventory APIs.
```

---

# 47. Phase 3 — Achievements and General Guild Administration

Implement the Achievement runtime with initial triggers:

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
- Guild/Raid achievement announcements.

Extend Guild Admin beyond rank assignment:

```text
member query
grant Achievement
increase/decrease Skill
give Item
request acknowledgement
receiver permission validation
```

All Guild Admin operations use the same targeted, receiver-validated protocol established for manual RPE Guild Rank assignment.

---

# 48. Phase 4 — Rank-Scoped Guild Progression

Implement:

- progression slots and entries defined per RPE Guild Rank;
- unlocked/locked state;
- narrative/locked text;
- spell selections;
- persisted progression state keyed by RPE Guild Rank ref;
- Progression UI for the assigned rank;
- officer Progression administration;
- remote progression mutations through Guild Admin.

Acceptance includes:

```text
Only the assigned valid RPE Guild Rank's progression is active/displayed.

Changing RPE Guild Rank does not delete previous rank-scoped progression state.

Dataset content controls names, descriptions and choices.

Locked entries cannot be selected.

Selected spells must exist in the configured progression entry.

Officer changes are validated by the target client.
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
Automatic RPE Guild Rank assignment from WoW guild rank
Automatic RPE Guild Rank hierarchy/inheritance
Multiple simultaneously active RPE Guild Ranks for one character
```

RPE SavedVariables remain fundamentally player-controlled.

---

# 50. Principal Architectural Decisions

**Achievement definitions remain Dataset data; progress remains Profile data.**

**Existing `Achievement.criteria` remains the central Achievement progression model.**

**All RPE object references use existing dataset-qualified references.**

**The internal `GuildSetting` class/collection is retained for compatibility, but the feature is exposed to users as RPE Guild Rank.**

**A guild has a catalogue of RPE Guild Ranks rather than one active GuildSetting.**

**One WoW guild rank may map to multiple RPE Guild Ranks.**

**A character has at most one assigned RPE Guild Rank per guild.**

**The assigned RPE Guild Rank is set manually by a WoW guild officer and is never inferred automatically.**

**WoW guild rank mapping constrains valid officer assignments; it does not select an RPE Guild Rank.**

**Multiple RPE Guild Ranks matching the same WoW guild rank are expected and are not a conflict.**

**Each RPE Guild Rank independently owns its Requisitions, Daily Rewards and Progression.**

**There is no implicit cross-rank inheritance.**

**Items remain in `RPEngineInventoryDB`; Guild systems use `Client.Inventory.AddItem()`.**

**Currencies use existing Profile currency APIs.**

**Skills use existing Profile skill APIs.**

**RPE kill Achievements trigger from the authoritative alive→dead resource-delta transition.**

**Guild Admin extends RPE's existing Comms system and uses targeted addon whispers.**

**The member's own client validates and applies every officer mutation, including RPE Guild Rank assignment.**

**Daily rewards are calendar-day based and cannot be duplicated by changing rank.**

**Requisition validation exists in the transaction layer, not merely the UI.**

**Rank changes preserve previous rank-scoped requisition/progression history rather than deleting it.**

This revision preserves the completed Phase 1 architecture while changing the Guild model from a single guild-wide setting into a manually assigned, dataset-driven RPE Guild Rank system.
