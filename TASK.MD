Bring the existing Guild Profile key into line with the PDD: use one centralized Guild identity helper based on the best stable Blizzard guild identity currently available, with a deterministic fallback, instead of guildName alone.
Baseline: current main after completed issue #21 / commit 271e9683de4cd60df1a2df2f1d5fbd8d4a9cc199.
- client/client_Guild.lua
- core/internal/profile/Guild.lua
- core/internal/database/Database.lua only if migration/normalization support is required
- current Guild Runtime/UI call sites found by repository search
The PDD requires one Guild helper to derive the Profile guild key from the best stable Blizzard guild identity available, with guild name/realm fallback.
Current code conceptually does:
```lua
local function getGuildKey(identity)
    return trimText(identity and identity.guildName)
end
```
This can theoretically collide for distinct guild identities sharing the same display name.
Before editing, inspect the current target-WoW guild APIs already used by RPE and determine the strongest stable identity actually available on this interface. Do not invent or assume a Blizzard identifier that the target client API does not expose.
Create/use one centralized Guild identity/key helper for all Guild Profile state access.
Fallback must remain deterministic and backward-compatible enough to recover existing name-keyed state.
Existing data such as:
```lua
profile.guild.byGuild[oldGuildName]
```
must not be abandoned.
When a stronger current key can be resolved:
- migrate or alias the old bucket only when source/target identity is unambiguous;
- preserve all nested data;
- do not destructively overwrite an already-populated new bucket;
- preserve unknown/future nested fields;
- never automatically assign, remap or clear assignedRankRef.
Preserve at least:
```text
assignedRankRef
assignedRankAt
assignedRankBy
dailyRewardDate
dailyRewardRankRef
dailyRewardTransaction
requisitions
progression
```
- Do not redesign Guild Rank catalogue semantics.
- Do not change WoW officer authorization.
- Do not change Requisition, Daily Reward or Progression business rules.
- Do not introduce another SavedVariable root.
- Do not infer a stable ID from rank/name ordering.
- Do not add Phase 5 Achievement behavior in this task.
- All Guild Profile lookups use one centralized guild-key helper.
- The key is stronger than guild name alone where the target WoW API exposes stronger identity.
- Existing name-keyed Guild Profile state remains accessible or migrates safely.
- Existing nested Guild state is preserved.
- Migration never automatically assigns/remaps/clears an RPE Guild Rank.
- Requisitions, Daily Rewards and Progression continue to resolve the same current guild state after migration.
- No unrelated gameplay behavior changes.
Read RPE2-Achievements-Guild-Systems-PDD.md, then inspect the current Guild identity helpers, all guildKey call sites, Profile Guild normalization, and the target WoW guild APIs before editing. Implement Task 0 only. Resolve the current code/PDD discrepancy with the smallest backward-compatible change; do not guess unsupported Blizzard APIs. When finished, review the diff against every acceptance criterion and report changed files, validation performed, and any deviation.