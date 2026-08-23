## Goal
Allow a WoW guild officer to set or clear an online member's RPE Guild Rank, with the target member's own RPE client validating and persisting the assignment.

Depends on: #12, #13, #14

## Primary files
- `core/internal/comms/Operations.lua`
- existing Comms send/dispatch files as required by current patterns
- `client/client_Guild.lua`
- `client/character/guild/page_GuildAdmin.lua`
- `core/internal/profile/Guild.lua`
- `core/internal/Runtime.lua` only if needed for refresh after acknowledgement

## Communications protocol
Inspect the current operation table before allocating opcodes. Do not assume a particular next opcode from the design document if the repository has changed.

Extend the existing RPE targeted addon-message transport and request/response conventions. Do not create another addon prefix or messaging subsystem.

Implement protocol support sufficient for:

```text
Guild Admin member query
set_guild_rank
clear_guild_rank
mutation acknowledgement
```

Messages must use the existing serialization/chunking and targeted addon `WHISPER` path.

The sender identity used for authorization must come from the addon-message transport, not a client-supplied payload field.

## Admin UI behavior
When an officer selects an online guild roster member:
- show the member's WoW guild rank;
- query the member's current RPE Guild Rank state;
- show RPE Guild Ranks eligible for that member's WoW guild rank according to the applicable catalogue;
- allow Set and Clear actions;
- expose pending/success/failure state clearly;
- do not optimistically display success before acknowledgement from the target client.

Only online members running compatible RPE can be administered. Offline Profile editing remains out of scope.

## Receiver-side validation
The target member's client must independently validate every rank mutation:

```text
sender identity came from transport
sender is in the same WoW guild
sender currently has WoW officer capability
target is this client's own active character
requested RPE Guild Rank exists
requested rank is applicable to this guild
requested rank allows this client's live WoW guild rank index
```

Do not trust client-supplied fields such as:

```lua
isOfficer = true
rankIndex = ...
targetIsEligible = true
```

for authorization/eligibility.

On success:
- persist through the Profile/Guild assignment APIs from Task 3;
- store assignment metadata where supported;
- refresh local Guild UI/state;
- send explicit acknowledgement.

Clear assignment must likewise be receiver-validated and persisted through the Profile API.

## Error/response behavior
Return an explicit response for supported failure cases such as:

```text
sender-not-in-guild
sender-not-officer
wrong-target
unknown-guild-rank
rank-not-applicable
rank-not-eligible
incompatible-protocol
```

Exact error tokens may follow current Comms conventions, but the officer UI must be able to distinguish success from failure/no response.

## Constraints
- Do not automatically assign an RPE Guild Rank on login, roster refresh or WoW rank change.
- Do not automatically remap or clear an invalid assignment.
- Do not grant officer capability based on RPE Guild Rank.
- Do not implement Achievement, Skill or Item admin mutations yet.
- Do not implement Requisition, Daily Reward or Progression runtime here.
- Do not directly write another player's SavedVariables; the target client applies its own mutation.

## Acceptance criteria
- [ ] Officer can query an online RPE member's assigned rank.
- [ ] Officer can set one of multiple eligible RPE Guild Ranks.
- [ ] Officer can clear the assignment.
- [ ] Non-officer UI cannot perform active assignment.
- [ ] Receiver rejects spoofed/non-officer senders.
- [ ] Receiver rejects a rank not applicable to its guild.
- [ ] Receiver rejects a rank not eligible for its own live WoW rank.
- [ ] Sender payload cannot override receiver-derived permission/rank state.
- [ ] Successful mutation persists in the target Profile.
- [ ] Explicit success/failure acknowledgement is returned.
- [ ] No rank is automatically assigned outside this officer operation.
- [ ] No Achievement/Skill/Item mutation is implemented yet.

## Coding-agent instructions
Read the revised PDD and implementation plan. Inspect the existing Comms operation registry, transport, request/response patterns, Guild facade and Admin page before editing. Implement Task 6 only. Receiver-side validation is authoritative; UI gating alone is not sufficient. Report changed files, validation performed and any deviation from this issue.