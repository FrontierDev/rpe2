## Goal
Allow existing Guild Requisition definitions to represent unlimited Guild Shop purchases without introducing a second shop dataset or persistence system.

Authoritative plan: `.docs/RPE2-Final-Guild-Requisitions-Page-Implementation-Plan.md`.

This task defines the business/data distinction used by the final page:

```text
characterLimit = 0  -> unlimited Guild Shop entry
characterLimit > 0  -> limited/one-time Requisition entry
```

Keep the existing default at `1` so all existing requisitions retain their current limited behavior unless explicitly authored as unlimited.

## Primary files
- `core/classes/GuildSetting.lua`
- `client/ui/editor/inspectors/page_InspectorGuildSetting.lua`
- `client/client_Guild.lua`

## GuildSetting normalization
In `core/classes/GuildSetting.lua`, change requisition normalization so `characterLimit` accepts `0` as the minimum valid value.

Conceptually:

```lua
characterLimit = normalizeInteger(source.characterLimit, 1, 0)
```

Do not add a separate `shop` array/field. `rank.requisitions` remains the sole definition collection.

## Authoring
Update the existing GuildSetting inspector Character Limit field so `0` can be entered, persisted, normalized, exported and reloaded without being coerced back to `1`.

Do not add explanatory/help text to the inspector. Preserve the existing field and surrounding editor structure.

## Eligibility behavior
In `Guild:GetRequisitionEligibility(...)`:

- normalize the effective limit with a minimum of `0`;
- preserve all existing Guild Rank, item, currency, affordability and inventory checks;
- when `characterLimit > 0`, preserve the existing usage-ledger lookup and `character-limit-reached` rejection;
- when `characterLimit == 0`, skip the usage-limit rejection entirely;
- return enough normalized detail for `TryRequisition(...)` to know whether the requisition is unlimited.

Do not make UI state authoritative for eligibility.

## Transaction behavior
In `Guild:TryRequisition(...)`:

- preserve the existing currency-spend transaction;
- preserve item award verification and rollback;
- preserve the usage-ledger increment/rollback path for `characterLimit > 0`;
- for `characterLimit == 0`, do **not** increment, set or otherwise write the requisition usage ledger;
- unlimited entries must remain repeatedly purchasable while the player remains otherwise eligible and can afford the cost.

Do not weaken transaction rollback behavior for limited requisitions.

## Backward compatibility
Existing definitions with absent/invalid `characterLimit` must continue to normalize to `1`.

Existing persisted usage for limited requisitions must remain authoritative and unchanged.

No Profile schema migration should be required: unlimited entries simply bypass the existing requisition usage ledger.

## Constraints
- Do not add a second Guild Shop definition collection.
- Do not add a second purchase API.
- Do not change currency transaction semantics.
- Do not change item award semantics.
- Do not change assigned Guild Rank resolution.
- Do not implement the final Requisitions page UI in this task.
- Do not change Daily Reward behavior in this task.

## Acceptance criteria
- [ ] `characterLimit = 0` survives GuildSetting normalization and round-trip.
- [ ] Existing/omitted limits still default to `1`.
- [ ] The GuildSetting inspector accepts and preserves `0`.
- [ ] `characterLimit = 0` bypasses the usage-limit eligibility check.
- [ ] Unlimited purchases do not write or increment the requisition usage ledger.
- [ ] Unlimited entries can be purchased repeatedly while affordable/eligible.
- [ ] `characterLimit > 0` retains the existing usage-limit and rollback behavior.
- [ ] Existing currency, item, Guild Rank and inventory validation remains unchanged.
- [ ] No new Profile schema or shop persistence root is introduced.

## Coding-agent instructions
Read `.docs/RPE2-Final-Guild-Requisitions-Page-Implementation-Plan.md`, then inspect the current `GuildSetting.lua` requisition normalizer, GuildSetting inspector Character Limit control, `Guild:GetRequisitionEligibility(...)`, `Guild:TryRequisition(...)`, and Profile requisition-ledger APIs before editing. Implement Task 0 only. Treat `rank.requisitions` and the existing transaction path as authoritative. Review every acceptance criterion and report changed files, validation performed, and any deviation.