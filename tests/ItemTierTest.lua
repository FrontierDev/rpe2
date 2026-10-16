local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then error(message, 2) end
end

local Addon = { Internal = {} }
local chunk, loadError = loadfile("core/internal/ItemTier.lua")
assert(chunk, loadError)
chunk(nil, Addon)

local ItemTier = Addon.Internal.ItemTier
assertEqual(ItemTier.Normalize(nil), "normal", "missing tier defaults to Normal")
assertEqual(ItemTier.Normalize(" HEROIC "), "heroic", "tier tokens are normalized")
assertTrue(ItemTier.IsValid("mythic"), "Mythic is a valid tier")
assertEqual(select(1, ItemTier.Validate("invalid")), nil, "invalid tier is rejected")
assertEqual(select(1, ItemTier.Validate("")), nil, "explicitly blank tier is rejected")
assertEqual(ItemTier.GetStatMultiplier("normal"), 1, "Normal has no stat bonus")
assertEqual(ItemTier.GetStatMultiplier("heroic"), 1.10, "Heroic uses the default stat bonus")
assertEqual(ItemTier.GetStatMultiplier("mythic"), 1.20, "Mythic uses the default stat bonus")
assertEqual(ItemTier.GetStatMultiplier("heroic", { heroicBonusPercent = 7 }), 1.07, "Heroic uses the configured stat bonus")
assertEqual(ItemTier.GetEffectiveQuality("rare", "mythic"), "epic", "Mythic raises Rare quality to Epic")
assertEqual(ItemTier.GetEffectiveQuality("epic", "mythic"), "epic", "Mythic quality is capped at Epic")
assertEqual(ItemTier.GetEffectiveQuality("rare", "heroic"), "rare", "Heroic does not change quality")
assertEqual(ItemTier.ResolveAuthoredStatValue({ sourceStatRef = "armor", value = 20 }, "heroic"), 22, "authored stat values are scaled")
assertEqual(ItemTier.ResolveAuthoredStatValue({ sourceStatRef = "armor", value = 1 }, "heroic"), 2, "flat tier-scaled stats round up")
assertEqual(ItemTier.ResolveAuthoredStatValue({ sourceStatRef = "hit", value = 1 }, "heroic", nil, { displayMode = "equip_percent" }), 1.1, "percentage stats are not rounded")
assertEqual(ItemTier.ResolveAuthoredStatValue({ sourceStatRef = "attack", value = -20 }, "mythic"), -24, "negative authored stat values preserve their sign")

print("ItemTierTest passed")
