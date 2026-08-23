## Goal
Activate the existing structural Guild Progression definitions as character state scoped to the character's assigned valid RPE Guild Rank, and add receiver-validated officer Progression administration.

Depends on: #12, #13, #15

## Primary files
- `client/client_Guild.lua` or a focused Guild progression module consistent with current organization
- `core/internal/profile/Guild.lua`
- `client/character/guild/page_GuildProgression.lua`
- `client/character/guild/page_GuildAdmin.lua`
- `core/internal/comms/Operations.lua` and existing Guild Admin protocol handlers

## Progression Profile state
Persist Progression state under the current guild bucket, keyed by qualified RPE Guild Rank reference:

```lua
profile.guild.byGuild[guildKey].progression[guildRankRef] = {
    slots = {},
    unlocked = {},
    selectedSpells = {},
}
```

Use the existing/final normalized Guild Profile shape rather than introducing another SavedVariable root.

State is rank-scoped:
- only the currently assigned **valid** RPE Guild Rank's Progression is active/displayed;
- changing assigned rank does not delete another rank's stored Progression state;
- switching back to a previously assigned rank restores its preserved state.

## Progression definition validation
Use the assigned Guild Rank's existing structural definition:

```lua
progression = {
    slotCount = 3,
    entries = {
        {
            id = "...",
            name = "...",
            description = "...",
            icon = "...",
            lockedText = "...",
            spellRefs = {},
        },
    },
}
```

Validate state against the current dataset definition:
- slot assignments must refer to configured entry IDs;
- locked entries cannot be actively selected/used where selection requires unlock;
- selected spells must be present in that entry's configured `spellRefs`;
- stale/invalid stored references should be handled safely without deleting unrelated rank state.

Do not hard-code campaign-specific concepts such as Squire, Knight, Crusader, Oath or Troth into RPE core.

## Progression UI
Render only the assigned valid rank's configured Progression.

The presentation should preserve the useful panel/entry model from the PDD using existing RPE UI primitives:
- entry name;
- icon;
- description;
- locked text/state;
- available/selected spell where applicable.

`slotCount = 3` is a default, not a hard data/UI limit. If more entries/slots exist than fit horizontally, use existing scrolling/pagination/layout patterns rather than assuming exactly three.

When no valid RPE Guild Rank is assigned, show a clean no-active-progression state and perform no mutation.

## Local mutation/business logic
Centralize Progression mutation/validation in Guild/Profile APIs rather than implementing write logic directly in the UI.

Operations should support the state required by the PDD, including:
- assigning an entry to a Progression slot;
- locking/unlocking an entry;
- selecting/clearing a configured spell as appropriate.

All writes must be scoped to the current guild and qualified `guildRankRef`.

## Officer Progression administration
Extend the existing Guild Admin request/response protocol/UI so an authorized WoW guild officer can administer an online compatible member's Progression.

Required officer operations:
- assign an entry to a Progression slot;
- lock/unlock an entry;
- clear an invalid/undesired selected spell.

The target member's client must independently validate:

```text
sender identity from transport
same-guild membership
sender WoW officer capability
target is this client's active character
currently assigned RPE Guild Rank is valid
requested progression entry/slot exists in that rank definition
requested selected spell state is valid
```

Do not trust sender-supplied officer or eligibility flags. Return explicit acknowledgement and do not optimistically report success in the officer UI.

## Constraints
- No valid assigned RPE Guild Rank -> no active Progression.
- Do not infer Progression from WoW guild rank directly.
- Do not automatically assign/remap an RPE Guild Rank.
- Do not delete prior rank-scoped Progression state when rank changes.
- Do not hard-code a three-entry data limit.
- Do not create a second Guild Admin messaging system.
- Do not directly write another member's SavedVariables from the officer client.

## Acceptance criteria
- [ ] No assigned/valid rank -> no active progression.
- [ ] Progression state is keyed by RPE Guild Rank ref.
- [ ] Switching ranks preserves prior rank state but activates only the current rank.
- [ ] Progression survives reload/relog.
- [ ] Locked entries cannot be selected.
- [ ] Selected spell must exist in configured `spellRefs`.
- [ ] UI is not hard-coded to exactly three entries.
- [ ] Officer remote mutations are receiver-validated and acknowledged.
- [ ] Core contains no campaign-specific rank/oath terminology.

## Coding-agent instructions
Read the revised PDD and implementation plan, then inspect the current structural Progression editor/data model, Profile Guild state and existing Guild Admin protocol before editing. Implement Task 11 only. Keep all state qualified by guild and RPE Guild Rank ref, reuse the existing Comms security boundary, and report changed files, validation performed and any deviation from this issue.