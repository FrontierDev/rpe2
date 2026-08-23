## Goal
Build the remaining Guild Admin operations on the receiver-validated request/response protocol introduced by Task 6.

Depends on: #15, #18

## Primary files
- `core/internal/comms/Operations.lua`
- existing Comms send/dispatch files as required by current patterns
- `client/client_Guild.lua`
- `client/character/guild/page_GuildAdmin.lua`
- Achievement runtime from #18
- existing Profile Skill APIs
- existing Inventory APIs

## Required Admin operations
Implement:

```text
grant_achievement
adjust_skill
give_item
```

Use the same targeted addon-message request/response architecture established by Task 6. Do not create a second Guild Admin protocol.

Extend the member query response only as needed for the Admin UI to display:
- Achievement earned/completion state;
- relevant Skill levels;
- assigned RPE Guild Rank.

Inventory contents do not need to be transmitted merely to give an item.

## Receiver-side validation
Every mutation must independently validate again:

```text
sender identity came from transport
sender is in the same WoW guild
sender currently has WoW officer capability
target is this client's own active character
requested operation is supported
referenced RPE object exists
numeric arguments are valid
```

Do not rely on:
- a previous successful member query;
- the officer UI being gated;
- payload fields claiming officer status;
- state cached only on the sender.

The target member's client is authoritative for applying its own Profile/Inventory mutation.

## Grant Achievement
Resolve the requested Achievement and apply through the Achievement runtime:

```lua
Achievements:Grant(achievementRef, {
    source = "guild_admin",
    actor = sender,
})
```

or equivalent current API.

Do not directly stamp `profile.achievements` in a way that bypasses normal completion/meta/UI/announcement handling.

## Adjust Skill
Resolve/validate the Skill reference and use existing Profile Skill APIs, conceptually:

```lua
local current = Profile.GetSkillLevel(skillRef)
Profile.SetSkillLevel(skillRef, current + delta)
```

Validate numeric delta/result according to the current Skill/Profile constraints. Do not write the underlying Profile table directly.

## Give Item
Resolve:

```lua
Registry:ResolveItemReference(itemRef)
```

then award through:

```lua
Client.Inventory.AddItem(...)
```

Validate quantity before mutation. Preserve existing stack/bind/Inventory behavior.

## Admin UI
For an online selected member, activate the relevant sections for officers:
- Achievements: display earned state and Grant action where appropriate;
- Skills: show level and Increase/Decrease controls;
- Items: select item, enter quantity, Give action.

The UI must:
- show pending state where practical;
- wait for explicit target acknowledgement;
- display failure reason rather than optimistically assuming success;
- keep the existing RPE Guild Rank Set/Clear operations functional.

## Responses
Every supported mutation returns an acknowledgement containing enough information to match the request and report success/failure, for example:

```lua
{
    requestId = "...",
    success = true,
    operation = "give_item",
}
```

or an explicit failure reason.

## Constraints
- Online compatible RPE members only; offline editing remains out of scope.
- Do not directly mutate another player's SavedVariables from the officer client.
- Do not weaken the receiver-side validation established in Task 6.
- Do not bypass Achievement, Skill or Inventory domain APIs.
- Do not break RPE Guild Rank Set/Clear administration.
- Progression administration belongs to Task 11.

## Acceptance criteria
- [ ] Officer can grant a valid Achievement to an online RPE member.
- [ ] Achievement uses normal completion/announcement behavior.
- [ ] Officer can increase/decrease a valid Skill within valid numeric bounds.
- [ ] Officer can give a valid Item/quantity through Inventory.
- [ ] Invalid references/quantities are rejected by receiver.
- [ ] Non-officer/spoofed senders are rejected.
- [ ] Each mutation receives explicit acknowledgement.
- [ ] Officer UI does not optimistically report success.
- [ ] Existing Guild Rank set/clear operations still work.

## Coding-agent instructions
Read the revised PDD and implementation plan, then inspect the Task 6 protocol, current Achievement runtime, Skill Profile APIs, Registry item resolution and Inventory award path before editing. Implement Task 10 only. Keep receiver validation authoritative and reuse existing domain APIs. Report changed files, validation performed and any deviation from this issue.