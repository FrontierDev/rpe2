local _, Addon = ...

Addon.Data = Addon.Data or {}

local DefaultRuleset = {
    id = "25076117",
    name = "Core",
    -- Bump when packaged rules change so existing Core records are rewritten.
    -- Version 2 introduced the mandatory setup-wizard gate.
    -- Version 3 adds explicit Cooldown Channel defaults.
    -- Version 4 removes the obsolete basic-attack GCD override.
    packageVersion = 4,
    export = [=[RPE_RULESET_V2
{ format = "rpe-ruleset", ruleset = { authorName = "Schutzenberg-ArgentDawn", description = "", id = "25076117", name = "Core", rules = { action_economy = { cooldown_channel_1_name = "Main Action", cooldown_channel_1_triggers_gcd = true, cooldown_channel_2_name = "Bonus Action", cooldown_channel_2_triggers_gcd = true, cooldown_channel_3_name = "Buff Action", cooldown_channel_3_triggers_gcd = true, cooldown_channel_4_name = "Free Action", cooldown_channel_4_triggers_gcd = false, cooldown_channel_5_name = "", cooldown_channel_5_triggers_gcd = false, cooldown_channel_6_name = "", cooldown_channel_6_triggers_gcd = false, cooldown_channel_7_name = "", cooldown_channel_7_triggers_gcd = false, cooldown_channel_8_name = "", cooldown_channel_8_triggers_gcd = false, cooldown_channel_9_name = "", cooldown_channel_9_triggers_gcd = false, cooldown_channel_10_name = "", cooldown_channel_10_triggers_gcd = false }, character = { action_bar_size = "8", starting_level = "60", use_base_resource_fallback = false, use_classes = true, use_level_system = true, use_races = true }, combat = { allow_block_without_shield = false, armor_class_stat = "", attack_roll_dice = "1d100", base_healing_crit_chance = "5", base_melee_crit_chance = "5", base_ranged_crit_chance = "5", base_spell_crit_chance = "5",  block_chance_stat = "f82db71a:p8syz5ba", complex_defence_stats_melee = {  }, complex_defence_stats_ranged = {  }, complex_defence_stats_spell = {  }, complex_healing_crit_stat = "", complex_melee_crit_stat = "", complex_ranged_crit_stat = "", complex_spell_crit_stat = "", critical_damage_mitigation_coefficient = "1", critical_damage_mitigation_mode = "percent", critical_damage_mitigation_model = "level_scaled_percent", critical_damage_mitigation_reference_amount = "140", critical_damage_mitigation_reference_level = "60", critical_damage_mitigation_reference_percent = "50", critical_damage_mitigation_stat = "f82db71a:0wyp78x9", critical_damage_multiplier = "2.0", critical_healing_multiplier = "2.0", critical_roll_dice = "1d100", crushing_blow_damage_multiplier = "1.5", damage_dealt_stat = "f82db71a:gj9wxb0x", damage_reduction_stat = "f82db71a:pu05li08", damage_school_mitigation_model = "level_scaled_percent", damage_school_mitigation_reference_level = "60", defence_roll_dice = "1d100", defence_system = "percent", defensive_reaction_limit_bypass_stats = { "f82db71a:p8syz5ba", "f82db71a:zs1nbz13" }, healing_done_stat = "f82db71a:5pxmfw02", healing_received_stat = "f82db71a:ok80ohz3", limit_defensive_reactions_per_turn = true, percent_base_penalty = "30", percent_healing_crit_stat = "f82db71a:69hfqhne", percent_melee_crit_stat = "f82db71a:jslmczbi", percent_melee_hit_stat = "f82db71a:wbj4zuf3", percent_melee_resistance_stat = { "f82db71a:tcn0s8kx", "f82db71a:o6113cir", "f82db71a:p8syz5ba" }, percent_ranged_crit_stat = "f82db71a:fercjhm5", percent_ranged_hit_stat = "f82db71a:dd88li4c", percent_ranged_resistance_stat = { "f82db71a:o6113cir", "f82db71a:p8syz5ba" }, percent_spell_crit_stat = "f82db71a:69hfqhne", percent_spell_hit_stat = "f82db71a:v2g0tw0o", percent_spell_resistance_stat = { "f82db71a:zs1nbz13" }, simple_attack_stat = "", simple_defence_stat = "", simple_healing_crit_stat = "", simple_melee_crit_stat = "", simple_ranged_crit_stat = "", simple_spell_crit_stat = "", spell_damage_vs_aberration_stat = "f82db71a:i52j0tj3", spell_damage_vs_beast_stat = "f82db71a:vgzlnifw", spell_damage_vs_demon_stat = "f82db71a:qh534ffl", spell_damage_vs_dragonkin_stat = "f82db71a:8mwchweb", spell_damage_vs_elemental_stat = "f82db71a:bh4yvi9u", spell_damage_vs_giant_stat = "f82db71a:x1lxi8cf", spell_damage_vs_humanoid_stat = "f82db71a:bj6h5ikw", spell_damage_vs_mechanical_stat = "f82db71a:k66l7jr4", spell_damage_vs_undead_stat = "f82db71a:qi323bx3", threat_generated_stat = "f82db71a:j8n012e6" }, consumables = { allow_consumable_traits = true, elixir_categorisation = true, elixir_limit = "0", flask_limit = "1", required_consumable_item_tags = "", rune_limit = "1", scroll_limit = "1" }, equipment = { allow_dual_wield = true, enforce_class_armor_weight_restrictions = true, mainhand_slot = "f82db71a:d212x0h1", offhand_slot = "f82db71a:l1hvib8g", ranged_slot = "f82db71a:q8ve6n6t", shield_slot = "f82db71a:l1hvib8g" }, event = { allowed_event_difficulties = { "normal", "heroic", "mythic" }, boss_kill_valor_currency = "25", event_end_justice_currency = "100", heroic_npc_damage_bonus_percent = "10", heroic_npc_defence_bonus = "0", heroic_npc_health_bonus_percent = "10", heroic_npc_hit_bonus = "0", initiative_stat = "", max_event_units = "5", mythic_npc_damage_bonus_percent = "25", mythic_npc_defence_bonus = "3", mythic_npc_health_bonus_percent = "25", mythic_npc_hit_bonus = "3", npc_health_bonus_per_player_percent = "3", player_scaling_challenge_levels = { "minor", "normal", "elite" } }, interface = { action_bar_layout = "complex", action_bar_size = "8", mounted_action_bar = true, mounted_action_bar_only_mounted_combat_spells = true, trait_display_mode = "grouped", use_item_level = true }, mounts = { allow_mount_in_combat = true, dismount_on_direct_damage = false, dismount_resistance_stat = "f82db71a:rmtjscxc", mounted_action_bar = true, mounted_action_bar_only_mounted_combat_spells = true, movement_range_stat = "f82db71a:s1mt6jh9" }, resources = { base_resource_fallback = "1.0", enable_resource_regeneration_per_turn = true, health_stat = "f82db71a:q2ktkztt", use_base_resource_fallback = true }, setup = { allowed_class_refs = { "b0211ab3:wvirv9um", "1c1038a7:nxlle3j6", "23d5dce2:ta9uh9xw", "7bbb4cb9:wvirv9um", "d7c874c4:02p0r8a2" }, allowed_race_refs = { "f82db71a:v17z463g", "f82db71a:xx3padtj" }, enable_setup_wizard = true, enable_skills_page = true, force_deactivate_other_datasets = false, forced_dataset_ids = { "f82db71a", "b0211ab3", "1c1038a7", "23d5dce2", "7bbb4cb9", "d7c874c4" }, permanent_skill_point_limit = "50", required_starting_item_slot_refs = { "f82db71a:nwfvxbto", "f82db71a:bgvs1zx6", "f82db71a:d212x0h1" }, starting_item_budget_copper = "100000", starting_item_tags = "starter" }, skills = { allow_permanent_skill_bonuses_after_setup = false, crafting_skill_max_level = "300", enable_crushing_blows = true, language_skill_gain_chance = "66", language_skill_max_level = "300", noncombat_skill_gain_chance_on_roll = "66", noncombat_skill_max_level = "80", skill_based_hit_chance = true, skill_roll_dice = "1d100", use_crafting_skills = true, use_language_skills = true, use_noncombat_skills = true, use_weapon_skills = true, weapon_skill_gain_chance_on_hit = "66", weapon_skill_level_multiplier = "5" }, stats = { health_stat = "f82db71a:q2ktkztt" }, traits = { allow_class_traits = true, allow_race_traits = true, auto_enable_class_traits = true, auto_enable_race_traits = true, base_talent_traits = 2, count_class_traits_toward_total = false, count_race_traits_toward_total = false, elixir_categorisation = true, enforce_class_talent_limit = true, max_total_traits = "10", talent_traits_per_level = "0" }, weapon_combat = { enable_crushing_blows = false, skill_based_hit_chance = true, weapon_skill_crit_modifier_cap = "25", weapon_skill_crit_modifier_per_point = "1", weapon_skill_hit_modifier_cap = "25", weapon_skill_hit_modifier_per_point = "1" } }, tagState = "standard" }, version = 2 }]=],
}

Addon.Data.DefaultRuleset = DefaultRuleset

local function logInstallDiagnostic(message)
    local debug = Addon.Debug or nil
    if debug and type(debug.Internal) == "function" then
        debug.Internal("Packaged default ruleset installation skipped: %s", tostring(message or "unknown error"))
    end
end

local function syncDefaultRuleset()
    local Database = Addon.Internal and Addon.Internal.Database or nil
    if type(Database) ~= "table" then
        logInstallDiagnostic("database module is unavailable")
        return false
    end
    if type(Database.EnsureRulesets) ~= "function"
        or type(Database.GetRulesetByID) ~= "function"
        or type(Database.ImportRuleset) ~= "function"
        or type(Database.GetActiveRulesetId) ~= "function"
        or type(Database.SetActiveRulesetId) ~= "function"
    then
        logInstallDiagnostic("ruleset synchronization API is unavailable")
        return false
    end

    -- ADDON_LOADED is the SavedVariables hand-off boundary. Rebind through the
    -- canonical database path rather than relying on frame-handler order.
    Database.EnsureRulesets()
    local globalEnvironment = _G or {}
    local savedRoot = rawget(globalEnvironment, "RPEngineRulesetDB")
    if type(savedRoot) ~= "table" or Database.Rulesets ~= savedRoot then
        Database.EnsureRulesets()
        savedRoot = rawget(globalEnvironment, "RPEngineRulesetDB")
    end
    if type(savedRoot) ~= "table" or Database.Rulesets ~= savedRoot then
        logInstallDiagnostic("ruleset SavedVariables root is not authoritative")
        return false
    end

    savedRoot.defaultRulesetVersions = type(savedRoot.defaultRulesetVersions) == "table"
        and savedRoot.defaultRulesetVersions
        or {}

    local packagedVersion = math.max(1, math.floor(tonumber(DefaultRuleset.packageVersion) or 1))
    local installedVersion = math.max(0, math.floor(tonumber(savedRoot.defaultRulesetVersions[DefaultRuleset.id]) or 0))
    local existing = Database.GetRulesetByID(DefaultRuleset.id)

    if existing == nil or installedVersion < packagedVersion then
        local imported, importError = Database.ImportRuleset(DefaultRuleset.export, {
            replaceExistingId = DefaultRuleset.id,
        })
        if type(imported) ~= "table" then
            logInstallDiagnostic(importError or "default ruleset import failed")
            return false
        end
        if tostring(imported.id or "") ~= DefaultRuleset.id then
            logInstallDiagnostic(("default ruleset imported with unexpected id '%s'"):format(tostring(imported.id or "")))
            return false
        end

        savedRoot.defaultRulesetVersions[DefaultRuleset.id] = packagedVersion
        existing = imported
    end

    -- The packaged Core ruleset is the fallback for any character without a
    -- valid active ruleset. A stale character-scoped ID must not prevent the
    -- fallback, while a valid user-selected ruleset remains untouched.
    local activeRulesetId = Database.GetActiveRulesetId()
    local activeRuleset = activeRulesetId and Database.GetRulesetByID(activeRulesetId) or nil
    if not activeRuleset then
        local activatedRulesetId = Database.SetActiveRulesetId(DefaultRuleset.id)
        if activatedRulesetId ~= DefaultRuleset.id then
            logInstallDiagnostic("Core ruleset could not be activated for the current character")
            return false
        end
    end

    return true
end

-- Runtime owns the ADDON_LOADED sequence.  Register this synchronizer there
-- so ruleset installation and character-scoped activation complete before any
-- first-login session or setup-wizard work runs.
Addon.Data.SyncDefaultRuleset = syncDefaultRuleset
