## Goal
Award the assigned RPE Guild Rank's Daily Rewards once per character, per guild, per calendar day without automatically assigning a rank.

Depends on: #15

## Primary files
- `client/client_Guild.lua` or a focused Guild reward module consistent with current organization
- `core/internal/Runtime.lua`
- `core/internal/profile/Guild.lua`
- `core/internal/profile/Currencies.lua`
- `client/character/inventory/Inventory.lua` as the existing item award path
- `client/character/guild/page_GuildRequisitions.lua`

## Runtime integration
Use the existing centralized Runtime event frame. Do not create a separate event frame for Daily Rewards.

Process/retry from appropriate existing login/guild-context events so rewards are attempted only when guild identity and roster/rank data are actually available.

The operation must be idempotent across repeated runtime events and `/reload`.

## Eligibility
Before any award, validate:

```text
player is in a guild
guild context is loaded
valid assigned RPE Guild Rank exists
enableDailyRewards is true
current guild/calendar day has not already been claimed
all Daily Reward definitions are valid/resolvable
```

Award only the character's valid assigned RPE Guild Rank rewards.

No assigned/valid rank must produce no reward and must never trigger automatic rank assignment.

## Award paths
Use existing canonical APIs:

### Item reward
```lua
Client.Inventory.AddItem(...)
```

### Currency reward
Use the existing Profile currency add API so caps and normal currency behavior remain intact.

Do not write directly to Inventory or Profile currency tables.

## Claim state
Store the completed claim in the current guild bucket using:

```lua
dailyRewardDate
dailyRewardRankRef
```

`dailyRewardDate` is a stable calendar-day key, for example:

```text
2026-08-23
```

Do **not** implement a rolling `timestamp + 86400` policy.

`dailyRewardRankRef` records which RPE Guild Rank supplied that day's reward.

The claim is **one reward claim per character, per guild, per calendar day**, not one claim per RPE Guild Rank. Changing RPE Guild Rank after claiming must not provide another reward that day.

## Transaction/idempotency behavior
Design the award/claim sequence so repeated Runtime events, `/reload` and relog cannot duplicate a completed claim.

Do not mark a claim successful before all required reward grants have been applied successfully.

If partial award failure is possible with the existing APIs, handle it coherently so retry behavior cannot create duplicated partial rewards.

## UI
Update the Daily Reward section on the Requisitions tab to report useful states such as:

```text
Not eligible: no RPE Guild Rank assigned
Daily rewards disabled
Available today
Received today
```

UI state is informational; runtime validation remains authoritative.

## Constraints
- Never automatically assign/remap/clear RPE Guild Rank.
- Do not permit a second claim after rank change on the same guild/calendar day.
- Do not introduce another event frame or SavedVariable root.
- Do not implement Requisition transaction changes beyond any shared helper strictly required.
- Do not implement Achievement or Progression runtime here.

## Acceptance criteria
- [ ] No assigned rank -> no reward and no auto-assignment.
- [ ] Invalid assigned rank -> no reward.
- [ ] Disabled Daily Rewards -> no reward.
- [ ] Item and currency rewards use canonical APIs.
- [ ] One claim per guild/calendar day survives reload/relog.
- [ ] Changing rank after claim does not yield a second reward.
- [ ] `dailyRewardRankRef` records which rank supplied the claimed reward.
- [ ] Guild context loading races do not duplicate rewards.
- [ ] UI accurately reports claimed/not-eligible state.

## Coding-agent instructions
Read the revised PDD and implementation plan, then inspect the existing Runtime event flow, Profile Guild state, currency API and Inventory award path before editing. Implement Task 8 only. Treat repeated Runtime events as normal and make processing idempotent. Report changed files, validation performed and any deviation from this issue.