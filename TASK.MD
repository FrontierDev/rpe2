## Goal
Remove the **runtime Guild Progression subsystem** from `client/client_Guild.lua`, including active progression resolution, local/remote progression mutations, and Guild Admin query payload progression state.

Authoritative plan: `.docs/RPE2-Remove-Guild-Progression-Implementation-Plan.md`.

Depends on: #51

This task is intentionally limited to the Guild client/runtime layer. Guild Admin visual controls, the Progression tab/page, and the GuildSetting editor are removed by later tasks.

## Primary file

- `client/client_Guild.lua`

Reference files to inspect before editing:

- `core/internal/profile/Guild.lua` after #51
- `core/internal/comms/Operations.lua`
- `client/character/guild/page_GuildAdmin.lua`
- `client/character/guild/page_GuildProgression.lua`

## 1. Remove active Guild Progression resolution

Delete Guild Progression-only helpers and APIs, including current equivalents of:

```text
normalizeProgressionSlotCount
getProgressionEntryMap
isConfiguredSpell
buildActiveGuildProgression
Guild:GetActiveGuildProgression
getProgressionMutationContext
persistProgressionMutation
```

Remove progression-only state/status handling such as:

```text
progression-disabled
progression-unavailable
no-active-progression
```

where those values have no remaining non-progression caller.

Do not remove generic Guild Rank resolution, requisition, Daily Reward, Achievement, Skill or Item logic.

## 2. Remove local Guild Progression mutation APIs

Delete current progression mutation APIs and aliases such as:

```text
Guild:AssignProgressionEntryToSlot
Guild:SetProgressionEntryUnlocked
Guild:SelectProgressionSpell
Guild:ClearProgressionSpell
SetProgressionSlot
UnlockProgressionEntry
LockProgressionEntry
SelectGuildProgressionSpell
ClearGuildProgressionSpell
```

Remove helpers whose only consumer was one of those APIs.

## 3. Remove progression state from Guild Admin query responses

Guild Admin member query responses currently serialize Achievements, Skills, and Progression.

Change the payload to carry only the still-supported Admin state:

```text
Achievements
Skills
```

Remove progression query helpers such as:

```text
appendQueryProgressionStateArguments
getProgressionQuerySnapshot
```

Update the response builder and parser so result/profile state no longer contains:

```lua
progression = ...
```

and no longer parses progression fields such as:

```text
active
rankRef
slotCount
slots
unlocked entries
selected spells
```

Do not leave placeholder progression fields merely to make the transport look unchanged.

## 4. Remove remote Guild Progression Admin mutation APIs

Delete request-side APIs such as current equivalents of:

```text
AssignProgressionEntryForMember
SetProgressionEntryLockForMember
ClearProgressionSpellForMember
```

Remove mutation operation strings and receiver-side dispatch branches for:

```text
assign_progression_entry
lock_progression_entry
unlock_progression_entry
clear_progression_spell
```

Remove progression-only validation/result codes if no longer referenced, including equivalents of:

```text
invalid-progression-slot
unknown-progression-entry
progression-entry-locked
invalid-progression-spell
no-active-progression
```

## 5. Preserve generic Guild Admin protocol/opcodes

Do **not** delete or renumber:

```text
GUILD_ADMIN_QUERY
GUILD_ADMIN_QUERY_RESPONSE
GUILD_ADMIN_MUTATION
GUILD_ADMIN_MUTATION_RESPONSE
```

These generic opcodes are still required for non-progression Guild Admin operations such as:

```text
Guild Rank assignment
Achievement grant
Skill adjustment
Item grant
```

Preserve all remaining mutation operation strings and transaction/acknowledgement behavior.

## 6. Decide protocol version deliberately

Inspect the current `GUILD_ADMIN_PROTOCOL_VERSION` and parser contract before changing it.

Because progression fields are being removed from the query response payload:

- if old/new clients could silently misparse positional fields, increment the protocol version and preserve the existing explicit incompatibility behavior;
- if the parser already treats the removed trailing fields as optional and mixed-version operation is demonstrably safe, a version bump is not required.

Do not guess. Base the decision on the actual current serializer/parser.

Report the decision and rationale in the task result.

## Acceptance criteria

- [ ] `client_Guild.lua` exposes no active Guild Progression resolution API.
- [ ] Local Guild Progression mutation APIs and aliases are removed.
- [ ] Guild Admin query responses contain no progression snapshot/state.
- [ ] Guild Admin query parsing contains no progression parser/state field.
- [ ] Remote Guild Progression Admin mutation request APIs are removed.
- [ ] Progression mutation operation strings/dispatch branches are removed.
- [ ] Unused progression-only error/result codes are removed.
- [ ] Generic Guild Admin query/mutation opcodes remain unchanged unless a documented protocol-version change requires otherwise.
- [ ] Guild Rank, Achievement, Skill and Item Admin operations remain intact.
- [ ] Requisition and Daily Reward runtime behavior remains unchanged.
- [ ] Protocol-version decision is explicitly validated and reported.

## Validation matrix

```text
Guild Admin query response
-> serializes Achievement state
-> serializes Skill state
-> does not serialize Progression state

Guild Admin response parser
-> reconstructs Achievement/Skill state
-> does not expect/store progression

set Guild Rank remotely
-> request/validation/ack still works

grant Achievement remotely
-> still works

adjust Skill remotely
-> still works

give Item remotely
-> still works

old progression mutation operation string received
-> no active progression mutation path remains
-> fails safely through existing unknown/unsupported-operation behavior

Requisitions / Daily Rewards
-> unaffected
```

## Constraints

- Do not delete the generic Guild Admin opcodes.
- Do not edit the Admin page UI in this task except for an unavoidable compile/load compatibility adjustment; #53 owns that cleanup.
- Do not delete `page_GuildProgression.lua` or the Guild tab here; #54 owns that cleanup.
- Do not edit the GuildSetting inspector here.
- Do not reintroduce Profile progression persistence removed by #51.
- Do not change non-progression Guild transaction semantics.

## Coding-agent instructions
Use current `FrontierDev/rpe2` as authoritative. This task is intended for **5.6-Luna-ExtraHigh**. Read `.docs/RPE2-Remove-Guild-Progression-Implementation-Plan.md` and completed #51 before editing. Trace each serializer/parser and mutation dispatch path end-to-end rather than deleting by name only. Preserve the four generic Guild Admin opcodes and all non-progression operations. Inspect mixed-version behavior before deciding whether to bump `GUILD_ADMIN_PROTOCOL_VERSION`. Report exact functions removed, protocol decision, files changed, and validation performed.