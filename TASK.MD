## Goal
Activate Requisition purchasing using only the character's valid assigned RPE Guild Rank.

Depends on: #15

## Primary files
- `client/client_Guild.lua` or a focused Guild transaction module consistent with current organization
- `core/internal/profile/Guild.lua`
- `core/internal/profile/Currencies.lua`
- `client/character/inventory/Inventory.lua` only as the existing award path/consumer
- `client/character/guild/page_GuildRequisitions.lua`

## Required transaction API
Use one central Guild operation such as:

```lua
Guild:TryRequisition(guildRankRef, requisitionId)
```

Exact naming may follow current patterns, but the UI must not perform transaction business logic directly.

## Validation order
Before spending any currency or awarding an item, validate:

```text
player is in the relevant guild
guild context is loaded
valid assigned RPE Guild Rank exists
requested guildRankRef equals the assigned rank
enableRequisitions is true
Requisition exists in that assigned rank
itemRef resolves
character lifetime limit is not reached
all currency refs resolve
all costs are affordable
inventory award is possible
```

Only then begin the commit.

Do not use legacy:

```lua
requiredGuildRankIndex
```

for eligibility. Rank access is determined by the manually assigned RPE Guild Rank.

## Transaction commit
On success:
- spend every required currency through existing Profile currency APIs;
- grant the configured quantity through `Client.Inventory.AddItem()`;
- increment the Profile Guild requisition ledger keyed by `guildRankRef` and Requisition ID;
- refresh the Guild/Requisitions UI.

The Requisition ledger is per character and per guild. `characterLimit` remains the lifetime limit for that Requisition definition within that RPE Guild Rank.

## Transaction safety
All costs must be validated before the first deduction.

If an unexpected failure occurs after spending begins, restore balances/state so the operation cannot leave a partial transaction.

Do not allow:

```text
some costs spent + no item
item granted + ledger not updated in a way that permits duplicate claiming
partial multi-currency deductions
```

Follow existing currency cap/normalization semantics rather than implementing a second currency system.

## Requisitions UI
Enable the existing Requisition action only when the centralized transaction API reports/derives valid eligibility.

Unavailable state should explain the reason where practical, for example:

```text
No RPE Guild Rank assigned
Requisitions disabled
Insufficient <currency>
Character limit reached
```

The UI is informative only; the transaction API must independently repeat validation.

## Constraints
- Do not infer eligibility from the player's WoW rank at purchase time beyond validating the existing assigned rank through the Guild facade.
- Do not use legacy minimum-rank hierarchy logic.
- Do not directly mutate Inventory storage outside `Client.Inventory.AddItem()`.
- Do not introduce Daily Reward behavior in this task.
- Do not change Achievement or Progression runtime.

## Acceptance criteria
- [ ] No assigned rank -> cannot requisition.
- [ ] Invalid assigned rank -> cannot requisition.
- [ ] Requisition from another rank -> rejected.
- [ ] Disabled Requisitions -> rejected.
- [ ] Multiple arbitrary currency costs work.
- [ ] Built-in `copper` works without dataset dependency assumptions.
- [ ] Insufficient currency causes no spending.
- [ ] Character lifetime limit is enforced per rank/requisition.
- [ ] Item grant uses `Client.Inventory.AddItem()`.
- [ ] Failed transaction cannot leave partial currency deductions.
- [ ] Successful usage persists through reload.
- [ ] Legacy minimum WoW-rank field is ignored.

## Coding-agent instructions
Read the revised PDD and implementation plan, then inspect current Profile currency, Inventory and Guild-state APIs before editing. Implement Task 7 only. Keep transaction validation centralized and atomic; do not rely on UI gating. Report changed files, validation performed and any deviation from this issue.