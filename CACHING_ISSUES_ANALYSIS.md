# RPEngine_Dev Stat Value Caching Issues - Comprehensive Analysis

## Quick Reference: Problem Locations

### CRITICAL ISSUES

#### 1. Unit Stat Entry Cache Not Invalidated
- **File**: [utils/Lookup.lua](utils/Lookup.lua)
- **Function**: `ensureUnitEntryCache()` 
- **Lines**: 70-99 (definition), 207-216 (usage in GetStatEntry)
- **Problem**: Cache stored on unit object (`unit.__rpeStatEntryCache`) only invalidates if array reference changes, not values
- **Impact**: Stale cached stat values persist after auras expire
- **Key Issue**: Line 76 - `if cached and cached.entries == entries then return cached` only checks reference equality

#### 2. Targeting Window Gets Stale Crit Values
- **File**: [client/client_Targeting.lua](client/client_Targeting.lua)
- **Function**: `buildSelectedUnitCritInfo()`
- **Lines**: 384 (function def), 412 (critical line)
- **Problem**: Line 412 gets crit stat via `Lookup.GetStatValue(casterUnit, critStatRef, 0)` which checks unit's `__rpeStatEntryCache` first
- **Impact**: Crit chance shown in targeting window doesn't update when auras expire
- **Code**: 
  ```lua
  local critStatValue = critStatRef and (Lookup.GetStatValue and Lookup.GetStatValue(casterUnit, critStatRef, 0) or 0) or 0
  ```

#### 3. Profile Resolution Called WITHOUT Aura Bonuses
- **File**: [utils/Lookup.lua](utils/Lookup.lua)
- **Function**: `Lookup.GetStatValue()`
- **Lines**: 224-230 (critical section)
- **Problem**: For local player, explicitly calls `Profile.GetResolvedStatValue(statRef, nil, { includeAuraBonuses = false })`
- **Impact**: Aura bonuses only applied as fallback in error case, not by default
- **Code**:
  ```lua
  if type(Profile.GetResolvedStatValue) == "function" then
      resolvedValue, foundResolved = Profile.GetResolvedStatValue(statRef, nil, {
          includeAuraBonuses = false,  -- <-- DISABLES AURA BONUSES!
      })
  end
  ```

---

## SECONDARY CACHING ISSUES

#### 4. Heal Combat Effect Stat Cache
- **File**: [client/combat/effects/Heal.lua](client/combat/effects/Heal.lua)
- **Function**: `Combat:ResolveHealingAmount()` and `Combat:ExecuteHealEffect()`
- **Lines**: 
  - 62-76: `getCachedModifierStatValue()` function definition
  - 123-127: Cache created in ResolveHealingAmount
  - 170-173: Cache reused in ExecuteHealEffect
- **Problem**: Context-level cache (`context.__rpeHealStatValueCache`) persists across multiple calculations
- **Cache key formula** (line 69): `unitKey .. "\31" .. normalizedStatRef`
- **Impact**: If context is reused, stale stat values persist
- **Code**:
  ```lua
  local cacheKey = unitKey .. "\31" .. normalizedStatRef
  local cachedValue = cache[cacheKey]
  if cachedValue ~= nil then
      return cachedValue  -- <-- Returns cached without re-checking auras
  end
  ```

#### 5. Resolver Stat Component Cache
- **File**: [core/internal/profile/Resolver.lua](core/internal/profile/Resolver.lua)
- **Function**: `resolveStatComponents()`
- **Lines**: 505-638 (function definition)
- **Problem**: Per-resolution-context cache stores computed stat values (line 638: `cache[entry.ref] = resolved`)
- **Cache check** (lines 512-515):
  ```lua
  if cache[entry.ref] ~= nil then
      return cache[entry.ref]  -- <-- Returns cached computed value
  end
  ```
- **Impact**: Within resolution context, if aura state changes, cached components aren't recalculated
- **Creation**: Fresh cache at line 844 in `buildStatResolutionContext()`

#### 6. Module-Level Recursion Tracking (Non-Exception-Safe)
- **File**: [utils/Lookup.lua](utils/Lookup.lua)
- **Variable**: `ApplyingAuraStatOverlay` (line 8, module-level static table)
- **Usage locations**:
  - Lines 250-265: Local player path
  - Lines 266-280: Non-local player path
- **Problem**: Flag set/cleared without exception safety (no pcall finally equivalent)
- **Code pattern** (lines 256-258):
  ```lua
  ApplyingAuraStatOverlay[overlayKey] = true
  local ok, value = pcall(auraManager.ApplyStatModifiers, auraManager, unit, statRef, baseValue)
  ApplyingAuraStatOverlay[overlayKey] = nil  -- <-- Not exception-safe
  ```
- **Risk**: If ApplyStatModifiers throws, flag isn't cleared, causing all future lookups to return base value

#### 7. AuraManager Bucket Not Cleared
- **File**: [client/spellcasting/AuraManager.lua](client/spellcasting/AuraManager.lua)
- **Function**: `BuildStatModifierTotals()`
- **Lines**: 2900-2950
- **Problem**: Iterates through `bucket.byKey` auras but relies on stacks being 0; no explicit entry removal when auras expire
- **Check** (line 2915):
  ```lua
  if type(entry) == "table" and tonumber(entry.targetEventId) == (tonumber(unitEventId) or 0) and (tonumber(entry.stacks) or 0) > 0 then
  ```
- **Issue**: If stacks aren't properly decremented or entries aren't removed, expired auras still apply bonuses

---

## Detailed Analysis by File

### [utils/Lookup.lua](utils/Lookup.lua)

| Line Range | Issue | Severity |
|-----------|-------|----------|
| 8 | Static `ApplyingAuraStatOverlay` table - can become orphaned | MEDIUM |
| 70-99 | `ensureUnitEntryCache()` - cache invalidation only checks array reference | **HIGH** |
| 207-216 | `GetStatEntry()` uses stale cache from line 70-99 | **HIGH** |
| 224-230 | Calls `GetResolvedStatValue()` with `includeAuraBonuses = false` | **HIGH** |
| 250-265 | Recursion tracking for local player (lines 256-258 not exception-safe) | MEDIUM |
| 266-280 | Recursion tracking for non-local players (lines 271-274 not exception-safe) | MEDIUM |

### [client/client_Targeting.lua](client/client_Targeting.lua)

| Line Range | Issue | Severity |
|-----------|-------|----------|
| 384 | `buildSelectedUnitCritInfo()` function definition | - |
| 412 | Gets crit stat via `Lookup.GetStatValue()` which returns cached values | **HIGH** |

### [client/combat/effects/Heal.lua](client/combat/effects/Heal.lua)

| Line Range | Issue | Severity |
|-----------|-------|----------|
| 62-76 | `getCachedModifierStatValue()` caches stat values | MEDIUM |
| 123-127 | Creates context cache `__rpeHealStatValueCache` | MEDIUM |
| 69 | Cache key formula includes unit and stat ref but doesn't track aura state | MEDIUM |
| 170-173 | Cache reused for multiple effect calculations | MEDIUM |
| 134, 173-175 | Cached values used for healing calculations | MEDIUM |

### [core/internal/profile/Resolver.lua](core/internal/profile/Resolver.lua)

| Line Range | Issue | Severity |
|-----------|-------|----------|
| 505-638 | `resolveStatComponents()` caches computed stat values | MEDIUM |
| 512-515 | Cache check returns stored component without recalculating | MEDIUM |
| 638 | Stores resolved component in cache: `cache[entry.ref] = resolved` | MEDIUM |
| 843-858 | `buildResolvedStatsByRef()` creates lookup tables (called per resolution) | LOW |
| 844 | Fresh cache created: `cache = {}` in `buildStatResolutionContext()` | - |
| 969-986 | Resources look up stats in `resolvedStatsByRef` | LOW |

### [client/spellcasting/AuraManager.lua](client/spellcasting/AuraManager.lua)

| Line Range | Issue | Severity |
|-----------|-------|----------|
| 2900-2950 | `BuildStatModifierTotals()` iterates active auras | - |
| 2915 | Only counts auras where `stacks > 0`; relies on proper cleanup | MEDIUM |
| 2920-2940 | Accumulates bonuses from active auras | - |

---

## Call Chain Analysis

### Targeting Window → Stale Crit Value
```
buildSelectedUnitCritInfo() [client_Targeting.lua:384]
  ↓ line 412
Lookup.GetStatValue(casterUnit, critStatRef, 0) [utils/Lookup.lua:196]
  ↓ line 207
Lookup.GetStatEntry(unit, statRef) [utils/Lookup.lua:202]
  ↓ line 207
ensureUnitEntryCache() [utils/Lookup.lua:70]
  ↓ line 76 - RETURNS CACHED
Returns stale value from unit.__rpeStatEntryCache
```

### Local Player Stat Resolution Without Auras
```
Lookup.GetStatValue(localPlayerUnit, statRef, fallback) [utils/Lookup.lua:196]
  ↓ (not in unit.stats)
isLocalPlayerUnit(unit) == true [utils/Lookup.lua:232]
  ↓ line 224
Profile.GetResolvedStatValue(statRef, nil, { includeAuraBonuses = false })
  ↓ RETURNS WITHOUT AURA BONUSES
Only applies aura bonus if first lookup fails (fallback path)
```

### Heal Effect Caching
```
Combat:ExecuteHealEffect(context, effect, component) [Heal.lua:117]
  ↓ line 170
statValueCache = context.__rpeHealStatValueCache [line 170-173]
  ↓ line 134
getCachedModifierStatValue(statValueCache, caster, entry.statRef)
  ↓ line 69-76
Returns cached value without checking current aura state
```

---

## Recommended Fixes

1. **Invalidate `__rpeStatEntryCache` when unit.stats changes**
   - Add version/timestamp tracking
   - Or clear cache on aura application/removal

2. **Call `Profile.GetResolvedStatValue()` with `includeAuraBonuses = true` by default**
   - Remove the false default; make it properly include aura bonuses

3. **Use exception-safe flag clearing**
   - Wrap `ApplyStatModifiers` in xpcall with cleanup guarantee
   - Or use a stack-based approach instead of overlay table

4. **Clear combat effect caches when auras change**
   - Don't reuse context caches across different spell applications
   - Or invalidate cache when aura state changes

5. **Ensure aura bucket entries are removed when auras expire**
   - Not just checking stacks == 0, but actually removing entries
   - Clear caches in AuraManager when auras are removed

6. **Add cache invalidation to aura removal events**
   - Listen for aura removal and clear all related stat caches
   - Use a dirty flag system to mark caches as invalid
