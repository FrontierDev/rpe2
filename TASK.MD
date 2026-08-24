Validation of current `main` (`74bfa9b`, Issue #35): **FAIL — leave open**.

The broad Phase 5 integration is coherent at source level, and the new `Achievements:RefreshIndex()` hook is read-only and correctly keeps the trigger index synchronized after local configuration changes. The previously completed Achievement reward/runtime/UI work also remains intact. However, the Guild identity fix in this revision introduces a backward-compatibility hole that violates Task 13's stable-Guild-state requirements.

### Blocking defect: previous `guildName-realm` buckets can become unreachable

Before Issue #35, `client/client_Guild.lua:getGuildIdentity()` filled an empty guild realm with `GetRealmName()`. Therefore, whenever `C_Club.GetGuildClubId()` was unavailable/empty, `Profile.GetGuildKey()` selected:

```text
GuildName-RealmName
```

and Phase 5 Guild state could legitimately be written there.

Issue #35 removes that `GetRealmName()` fallback. On the target API, `GetGuildInfo("player")` returns the guild realm as `nil` for a same-realm guild. With Club ID unavailable, the current code therefore selects:

```text
GuildName
```

instead.

The migration helper does not recover the previous realm-qualified bucket in this case. `getLegacyGuildKeys(identity)` only adds `GuildName-RealmName` when `identity.realmName` / `guildRealm` / `realm` is non-empty. After this revision, a same-realm identity has none of those values, so the helper only probes `GuildName`.

Concrete regression:

1. Run the pre-#35 build while `C_Club.GetGuildClubId()` is temporarily unavailable.
2. Same-realm guild `Example Guild` resolves via the old fallback to `Example Guild-MyRealm`.
3. Store any current Guild state there, e.g. `assignedRankRef`, requisition usage, daily reward transaction, or progression slots.
4. Update to Issue #35.
5. `GetGuildInfo("player")` supplies no realm for this same-realm guild and Club ID is still unavailable.
6. New key resolves to `Example Guild`.
7. `migrateLegacyGuildBucket()` never looks at `Example Guild-MyRealm` because the identity no longer carries `MyRealm`.
8. The previously persisted Guild state appears lost/inaccessible.
9. If Club ID later becomes available, migration to `guild:<clubId>` still only considers `Example Guild`, so the orphaned realm-qualified bucket remains skipped.

This directly violates:
- existing Guild Profile state remains accessible/migrates safely;
- the key transition must not split the current guild's Profile state;
- assignment/Requisition/Daily Reward/Progression nested data survives.

### Required fix

It is reasonable to keep the new **current fallback key** name-only for same-realm guilds, but migration still needs to know the legacy local realm so it can recover the key format used by the prior build.

For example:
- retain `GetRealmName()` as a separate migration-only identity field such as `legacyRealmName` / `localRealmName`; and
- have `getLegacyGuildKeys()` consider `GuildName-<local realm>` in addition to `GuildName`, without making that realm-qualified form the selected current fallback key.

When Club ID is available, migration should likewise consider both prior forms before returning `guild:<clubId>`. Preserve the current non-destructive merge precedence and do not alter `assignedRankRef` semantics.

### Other integration checks

Source review confirms the final tree still has:
- all 11 supported Achievement triggers indexed and authorable;
- index rebuild itself read-only;
- canonical Inventory add notifications and positive Skill deltas feeding Achievement progress;
- committed/transport-bound damage, healing, kill and boss-kill hooks;
- event-start dispatch from accepted client Event start with per-instance idempotency;
- schema 17/7 monotonic markers;
- structured Item/Currency reward normalization, dependency/runtime/UI paths from Tasks 8–12;
- reward persistence, rollback/recovery blocking and explicit safe retry semantics;
- Profile Achievement reward display/retry restrictions;
- one runtime event frame and no new SavedVariable root;
- load order where Profile APIs exist before Achievement runtime/UI consumers and Achievement listeners initialize only on `ADDON_LOADED`, after Inventory has loaded.

No combined CI statuses or GitHub Actions workflow runs are configured for `74bfa9b`.

Issue #35 should remain open until the realm-qualified legacy Guild bucket is recoverable under the revised identity fallback.