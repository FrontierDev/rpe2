Implement Task 1 from `RPE2-Guild-Rank-Revision-Codex-Implementation-Plan.md` against the revised `RPE2-Achievements-Guild-Systems-PDD.md`.

Extend the existing internal `GuildSetting` model with normalized `wowGuildRankIndices`: non-negative integer array, invalid values dropped, duplicates removed deterministically, empty means unrestricted. Keep internal `GuildSetting`/`guildSettings` names for compatibility. Bump Dataset schema from 15 to 16 without lowering future markers.

Preserve legacy Requisition `requiredGuildRankIndex` data during normalization/serialization, but do not auto-convert it into the new mapping and do not add runtime behavior.

Acceptance: old Phase 1 datasets load; mappings normalize and export/import correctly; existing Requisitions/Daily Rewards/Progression/tags survive; legacy rank data is not destroyed; no Profile assignment, Guild UI, Comms or gameplay behavior is added.

Implement Task 1 only and review the diff against the full Task 1 section in the implementation plan.