from pathlib import Path


def replace_once(text, old, new, label):
    if old not in text:
        raise SystemExit(f"missing anchor: {label}")
    if text.count(old) != 1:
        raise SystemExit(f"unexpected anchor count for {label}: {text.count(old)}")
    return text.replace(old, new, 1)


def require_count(text, needle, expected, label):
    actual = text.count(needle)
    if actual != expected:
        raise SystemExit(f"{label}: expected {expected}, got {actual}")


# ---------------------------------------------------------------------------
# Database persistence
# ---------------------------------------------------------------------------
db_path = Path("core/internal/database/Database.lua")
db = db_path.read_text(encoding="utf-8")

bonus_normalizer = '''local function normalizeProfileSkillPermanentBonuses(record)\n    local normalized = {}\n\n    for skillRef, storedValue in pairs(ensureTable(record)) do\n        local normalizedSkillRef = ensureString(skillRef, "")\n        local normalizedValue = math.max(0, math.floor(tonumber(storedValue) or 0))\n        if normalizedSkillRef ~= "" and normalizedValue > 0 then\n            normalized[normalizedSkillRef] = normalizedValue\n        end\n    end\n\n    return normalized\nend\n\n'''

db = replace_once(
    db,
    'local function normalizeProfileSkillLevels(record)\n',
    bonus_normalizer + 'local function normalizeProfileSkillLevels(record)\n',
    "skill level normalizer",
)

db = replace_once(
    db,
    '        skillLevels = normalizeProfileSkillLevels(data.skillLevels),\n',
    '        skillLevels = normalizeProfileSkillLevels(data.skillLevels),\n'
    '        skillPermanentBonuses = normalizeProfileSkillPermanentBonuses(data.skillPermanentBonuses),\n',
    "normalized profile skill levels",
)

bonus_api = '''function Database.ListProfileSkillPermanentBonuses()\n    local profile = Database.GetOrCreateActiveProfile()\n    profile.skillPermanentBonuses = normalizeProfileSkillPermanentBonuses(profile.skillPermanentBonuses)\n\n    local copy = {}\n    for skillRef, value in pairs(profile.skillPermanentBonuses) do\n        copy[skillRef] = value\n    end\n    return copy\nend\n\nfunction Database.GetProfileSkillPermanentBonus(skillRef)\n    local normalizedSkillRef = ensureString(skillRef, "")\n    if normalizedSkillRef == "" then\n        return 0\n    end\n\n    local profile = Database.GetOrCreateActiveProfile()\n    profile.skillPermanentBonuses = normalizeProfileSkillPermanentBonuses(profile.skillPermanentBonuses)\n    return math.max(0, math.floor(tonumber(profile.skillPermanentBonuses[normalizedSkillRef]) or 0))\nend\n\nfunction Database.SetProfileSkillPermanentBonus(skillRef, value)\n    local normalizedSkillRef = ensureString(skillRef, "")\n    if normalizedSkillRef == "" then\n        return nil\n    end\n\n    local profile = Database.GetOrCreateActiveProfile()\n    profile.skillPermanentBonuses = normalizeProfileSkillPermanentBonuses(profile.skillPermanentBonuses)\n    local previousValue = math.max(0, math.floor(tonumber(profile.skillPermanentBonuses[normalizedSkillRef]) or 0))\n    local normalizedValue = math.max(0, math.floor(tonumber(value) or 0))\n    if normalizedValue > 0 then\n        profile.skillPermanentBonuses[normalizedSkillRef] = normalizedValue\n    else\n        profile.skillPermanentBonuses[normalizedSkillRef] = nil\n    end\n    if previousValue ~= normalizedValue then\n        notifyConfigurationChanged("profile-skills")\n    end\n    return normalizedValue\nend\n\nfunction Database.ClearProfileSkillPermanentBonus(skillRef)\n    local normalizedSkillRef = ensureString(skillRef, "")\n    if normalizedSkillRef == "" then\n        return false\n    end\n\n    local profile = Database.GetOrCreateActiveProfile()\n    profile.skillPermanentBonuses = normalizeProfileSkillPermanentBonuses(profile.skillPermanentBonuses)\n    local existed = profile.skillPermanentBonuses[normalizedSkillRef] ~= nil\n    profile.skillPermanentBonuses[normalizedSkillRef] = nil\n    if existed then\n        notifyConfigurationChanged("profile-skills")\n    end\n    return existed\nend\n\n'''

db = replace_once(
    db,
    'function Database.ListProfileSkillLevels()\n',
    bonus_api + 'function Database.ListProfileSkillLevels()\n',
    "profile skill-level API",
)

db_path.write_text(db, encoding="utf-8")


# ---------------------------------------------------------------------------
# Profile facade
# ---------------------------------------------------------------------------
profile_path = Path("core/internal/profile/Profile.lua")
profile = profile_path.read_text(encoding="utf-8")

profile_bonus_api = '''function Profile.ListSkillPermanentBonuses()\n    if Database.ListProfileSkillPermanentBonuses then\n        return Database.ListProfileSkillPermanentBonuses()\n    end\n\n    return {}\nend\n\nfunction Profile.GetSkillPermanentBonus(skillRef)\n    if Database.GetProfileSkillPermanentBonus then\n        return Database.GetProfileSkillPermanentBonus(skillRef)\n    end\n\n    return 0\nend\n\nfunction Profile.SetSkillPermanentBonus(skillRef, value)\n    if Database.SetProfileSkillPermanentBonus then\n        return Database.SetProfileSkillPermanentBonus(skillRef, value)\n    end\n\n    return nil\nend\n\nfunction Profile.ClearSkillPermanentBonus(skillRef)\n    if Database.ClearProfileSkillPermanentBonus then\n        return Database.ClearProfileSkillPermanentBonus(skillRef)\n    end\n\n    return false\nend\n\n'''

profile = replace_once(
    profile,
    'function Profile.ListSkillLevels()\n',
    profile_bonus_api + 'function Profile.ListSkillLevels()\n',
    "profile skill-level facade",
)
profile_path.write_text(profile, encoding="utf-8")


# ---------------------------------------------------------------------------
# Resolved skill values
# ---------------------------------------------------------------------------
resolver_path = Path("core/internal/profile/Resolver.lua")
resolver = resolver_path.read_text(encoding="utf-8")

resolver_bonus_map = '''local function buildProfileSkillPermanentBonusMap()\n    local bonuses = {}\n    local profile = Database.GetActiveProfile and Database.GetActiveProfile() or nil\n    local storedBonuses = profile and profile.skillPermanentBonuses or nil\n\n    for skillRef, value in pairs(type(storedBonuses) == "table" and storedBonuses or {}) do\n        local normalizedSkillRef = ensureString(skillRef)\n        if normalizedSkillRef ~= "" then\n            bonuses[normalizedSkillRef] = math.max(0, math.floor(tonumber(value) or 0))\n        end\n    end\n\n    return bonuses\nend\n\n'''

resolver = replace_once(
    resolver,
    'local function buildProfileSkillLevelMap()\n',
    resolver_bonus_map + 'local function buildProfileSkillLevelMap()\n',
    "profile skill level map",
)

resolver = replace_once(
    resolver,
    'local function buildResolvedSkillRow(entry, resolvedStatsByRef, storedLevels, itemBonuses, traitBonuses, raceBonuses, classBonuses, auraContext, level, weaponMultiplier)\n',
    'local function buildResolvedSkillRow(entry, resolvedStatsByRef, storedLevels, permanentBonuses, itemBonuses, traitBonuses, raceBonuses, classBonuses, auraContext, level, weaponMultiplier)\n',
    "resolved skill row signature",
)

resolver = replace_once(
    resolver,
    '    local itemBonus = tonumber(itemBonuses and itemBonuses[entry.ref]) or 0\n'
    '    local traitBonus = tonumber(traitBonuses and traitBonuses[entry.ref]) or 0\n'
    '    local raceBonus = tonumber(raceBonuses and raceBonuses[entry.ref]) or 0\n'
    '    local classBonus = tonumber(classBonuses and classBonuses[entry.ref]) or 0\n'
    '    local auraBonus = resolveAuraBonusForSkill(auraContext, entry.ref)\n'
    '    local bonusValue = itemBonus + traitBonus + raceBonus + classBonus + auraBonus\n',
    '    local permanentBonus = tonumber(permanentBonuses and permanentBonuses[entry.ref]) or 0\n'
    '    local itemBonus = tonumber(itemBonuses and itemBonuses[entry.ref]) or 0\n'
    '    local traitBonus = tonumber(traitBonuses and traitBonuses[entry.ref]) or 0\n'
    '    local raceBonus = tonumber(raceBonuses and raceBonuses[entry.ref]) or 0\n'
    '    local classBonus = tonumber(classBonuses and classBonuses[entry.ref]) or 0\n'
    '    local auraBonus = resolveAuraBonusForSkill(auraContext, entry.ref)\n'
    '    local bonusValue = permanentBonus + itemBonus + traitBonus + raceBonus + classBonus + auraBonus\n',
    "resolved skill bonuses",
)

resolver = replace_once(
    resolver,
    '        maxValue = maxValue,\n        itemBonus = itemBonus,\n',
    '        maxValue = maxValue,\n        permanentBonus = permanentBonus,\n        itemBonus = itemBonus,\n',
    "resolved skill row bonus fields",
)

stored_anchor = '    local storedLevels = buildProfileSkillLevelMap()\n    local itemBonuses = buildItemSkillBonusMap()\n'
require_count(resolver, stored_anchor, 2, "resolved skill map construction")
resolver = resolver.replace(
    stored_anchor,
    '    local storedLevels = buildProfileSkillLevelMap()\n'
    '    local permanentBonuses = buildProfileSkillPermanentBonusMap()\n'
    '    local itemBonuses = buildItemSkillBonusMap()\n',
)

call_anchor = 'buildResolvedSkillRow(entry, resolvedStatsByRef, storedLevels, itemBonuses, traitBonuses, raceBonuses, classBonuses, auraContext, level, weaponMultiplier)'
require_count(resolver, call_anchor, 2, "resolved skill row calls")
resolver = resolver.replace(
    call_anchor,
    'buildResolvedSkillRow(entry, resolvedStatsByRef, storedLevels, permanentBonuses, itemBonuses, traitBonuses, raceBonuses, classBonuses, auraContext, level, weaponMultiplier)',
)
resolver_path.write_text(resolver, encoding="utf-8")


# ---------------------------------------------------------------------------
# Dataset-reference cleanup for profile-owned skill data
# ---------------------------------------------------------------------------
deps_path = Path("core/internal/database/Dependecies.lua")
deps = deps_path.read_text(encoding="utf-8")

remove_dataset_anchor = '''            if type(profile) == "table" and type(profile.skillLevels) == "table" then\n                for skillRef in pairs(profile.skillLevels) do\n                    local sourceDatasetId = Dependecies.ParseSourceStatRef(skillRef)\n                    if sourceDatasetId == datasetId then\n                        profile.skillLevels[skillRef] = nil\n                    end\n                end\n            end\n            if type(profile) == "table" and type(profile.skillActionBar) == "table" then\n'''
remove_dataset_replacement = '''            if type(profile) == "table" and type(profile.skillLevels) == "table" then\n                for skillRef in pairs(profile.skillLevels) do\n                    local sourceDatasetId = Dependecies.ParseSourceStatRef(skillRef)\n                    if sourceDatasetId == datasetId then\n                        profile.skillLevels[skillRef] = nil\n                    end\n                end\n            end\n            if type(profile) == "table" and type(profile.skillPermanentBonuses) == "table" then\n                for skillRef in pairs(profile.skillPermanentBonuses) do\n                    local sourceDatasetId = Dependecies.ParseSourceStatRef(skillRef)\n                    if sourceDatasetId == datasetId then\n                        profile.skillPermanentBonuses[skillRef] = nil\n                    end\n                end\n            end\n            if type(profile) == "table" and type(profile.skillActionBar) == "table" then\n'''
deps = replace_once(deps, remove_dataset_anchor, remove_dataset_replacement, "dataset skill cleanup")

remove_skill_anchor = '''                if type(profile) == "table" and type(profile.skillLevels) == "table" then\n                    profile.skillLevels[deletedRef] = nil\n                end\n                if type(profile) == "table" and type(profile.skillActionBar) == "table" then\n'''
remove_skill_replacement = '''                if type(profile) == "table" and type(profile.skillLevels) == "table" then\n                    profile.skillLevels[deletedRef] = nil\n                end\n                if type(profile) == "table" and type(profile.skillPermanentBonuses) == "table" then\n                    profile.skillPermanentBonuses[deletedRef] = nil\n                end\n                if type(profile) == "table" and type(profile.skillActionBar) == "table" then\n'''
deps = replace_once(deps, remove_skill_anchor, remove_skill_replacement, "single skill cleanup")
deps_path.write_text(deps, encoding="utf-8")


# ---------------------------------------------------------------------------
# Skills page context menu
# ---------------------------------------------------------------------------
ui_path = Path("client/character/profile/page_ProfileSkills.lua")
ui = ui_path.read_text(encoding="utf-8")

ui = replace_once(
    ui,
    'local CRAFTING_UI_INTERNAL_TRACE = false\n',
    'local CRAFTING_UI_INTERNAL_TRACE = false\nlocal SKILL_BONUS_POPUP_KEY = "RPE_PROFILE_SKILL_PERMANENT_BONUS"\n',
    "skills page constants",
)

skill_menu_methods = '''function SkillsPage:RefreshAfterSkillManualAdjustment()\n    self.SkillListSession = nil\n    self:MarkDirty()\n    self:Refresh()\nend\n\nfunction SkillsPage:AddPermanentSkillBonus(skillRef, amount)\n    local normalizedAmount = math.max(0, math.floor(tonumber(amount) or 0))\n    if normalizedAmount <= 0 or type(Profile.SetSkillPermanentBonus) ~= "function" then\n        return false\n    end\n\n    local current = type(Profile.GetSkillPermanentBonus) == "function"\n        and math.max(0, math.floor(tonumber(Profile.GetSkillPermanentBonus(skillRef)) or 0))\n        or 0\n    if Profile.SetSkillPermanentBonus(skillRef, current + normalizedAmount) == nil then\n        return false\n    end\n\n    self:RefreshAfterSkillManualAdjustment()\n    return true\nend\n\nfunction SkillsPage:ResetSkillPermanentBonus(skillRef)\n    if type(Profile.ClearSkillPermanentBonus) ~= "function" then\n        return false\n    end\n\n    local changed = Profile.ClearSkillPermanentBonus(skillRef) == true\n    if changed then\n        self:RefreshAfterSkillManualAdjustment()\n    end\n    return changed\nend\n\nfunction SkillsPage:ResetSkillGainedLevels(skillRef)\n    if type(Profile.ClearSkillLevel) ~= "function" then\n        return false\n    end\n\n    local changed = Profile.ClearSkillLevel(skillRef) == true\n    if changed then\n        self:RefreshAfterSkillManualAdjustment()\n    end\n    return changed\nend\n\nfunction SkillsPage:ResetSkillBonusAndGainedLevels(skillRef)\n    local bonusChanged = type(Profile.ClearSkillPermanentBonus) == "function"\n        and Profile.ClearSkillPermanentBonus(skillRef) == true\n        or false\n    local levelChanged = type(Profile.ClearSkillLevel) == "function"\n        and Profile.ClearSkillLevel(skillRef) == true\n        or false\n\n    if bonusChanged or levelChanged then\n        self:RefreshAfterSkillManualAdjustment()\n        return true\n    end\n    return false\nend\n\nfunction SkillsPage:EnsureSkillBonusPopup()\n    if type(StaticPopupDialogs) ~= "table" then\n        return false\n    end\n    if StaticPopupDialogs[SKILL_BONUS_POPUP_KEY] then\n        return true\n    end\n\n    StaticPopupDialogs[SKILL_BONUS_POPUP_KEY] = {\n        text = "Add permanent bonus to %s:",\n        button1 = ACCEPT,\n        button2 = CANCEL,\n        hasEditBox = true,\n        timeout = 0,\n        whileDead = true,\n        hideOnEscape = true,\n        OnShow = function(dialog)\n            if dialog and dialog.editBox then\n                dialog.editBox:SetText("1")\n                dialog.editBox:HighlightText()\n                dialog.editBox:SetFocus()\n            end\n        end,\n        OnAccept = function(dialog)\n            local data = dialog and dialog.data or nil\n            local page = data and data.page or nil\n            local skillRef = data and data.skillRef or nil\n            local amount = dialog and dialog.editBox and tonumber(dialog.editBox:GetText()) or nil\n            amount = math.floor(tonumber(amount) or 0)\n            if page and skillRef and amount > 0 then\n                page:AddPermanentSkillBonus(skillRef, amount)\n            end\n        end,\n        EditBoxOnEnterPressed = function(editBox)\n            local dialog = editBox and editBox:GetParent() or nil\n            if dialog and dialog.button1 and dialog.button1.Click then\n                dialog.button1:Click()\n            end\n        end,\n        EditBoxOnEscapePressed = function(editBox)\n            local dialog = editBox and editBox:GetParent() or nil\n            if dialog and dialog.Hide then\n                dialog:Hide()\n            end\n        end,\n    }\n    return true\nend\n\nfunction SkillsPage:PromptPermanentSkillBonus(skillRef)\n    if type(StaticPopup_Show) ~= "function" or not self:EnsureSkillBonusPopup() then\n        return false\n    end\n\n    local row = self:FindSkillRow(skillRef, self.AllSkillRows)\n    local skillName = tostring(row and row.name or "Skill")\n    local popup = StaticPopup_Show(SKILL_BONUS_POPUP_KEY, skillName)\n    if not popup then\n        return false\n    end\n\n    popup.data = {\n        page = self,\n        skillRef = skillRef,\n    }\n    return true\nend\n\nfunction SkillsPage:EnsureSkillContextMenu()\n    if self.SkillContextMenu then\n        return self.SkillContextMenu\n    end\n\n    self.SkillContextMenu = UI.ContextMenu:New({\n        name = "RPEProfileSkillsSkillContextMenu",\n        width = 210,\n        panelWidth = 210,\n        visibleRows = 4,\n        rowHeight = 18,\n        border = false,\n        onItemInvoked = function(item, menu)\n            local action = item and item.value or nil\n            local skillRef = self.ContextMenuSkillRef\n            if not action or not skillRef then\n                return\n            end\n\n            if menu and menu.HideMenus then\n                menu:HideMenus()\n            end\n\n            if action == "add-permanent-bonus" then\n                self:PromptPermanentSkillBonus(skillRef)\n            elseif action == "reset-permanent-bonus" then\n                self:ResetSkillPermanentBonus(skillRef)\n            elseif action == "reset-gained-levels" then\n                self:ResetSkillGainedLevels(skillRef)\n            elseif action == "reset-bonus-and-levels" then\n                self:ResetSkillBonusAndGainedLevels(skillRef)\n            end\n        end,\n    })\n    self.SkillContextMenu:SetParent(self.frame or UIParent)\n    self.SkillContextMenu:Create()\n    return self.SkillContextMenu\nend\n\nfunction SkillsPage:ShowSkillContextMenu(anchorFrame, row)\n    if not anchorFrame or type(row) ~= "table" or not row.ref then\n        return\n    end\n\n    local permanentBonus = type(Profile.GetSkillPermanentBonus) == "function"\n        and math.max(0, math.floor(tonumber(Profile.GetSkillPermanentBonus(row.ref)) or 0))\n        or 0\n    local storedLevel = type(Profile.GetSkillLevel) == "function"\n        and math.max(0, math.floor(tonumber(Profile.GetSkillLevel(row.ref)) or 0))\n        or 0\n    local hasBonus = permanentBonus > 0\n    local hasGainedLevels = storedLevel > 0\n\n    self.ContextMenuSkillRef = row.ref\n    local menu = self:EnsureSkillContextMenu()\n    menu:SetItems({\n        { label = "Add Permanent Bonus...", value = "add-permanent-bonus" },\n        { label = "Reset Permanent Bonus", value = "reset-permanent-bonus", enabled = hasBonus },\n        { label = "Reset Gained Levels", value = "reset-gained-levels", enabled = hasGainedLevels },\n        { label = "Reset Bonus & Gained Levels", value = "reset-bonus-and-levels", enabled = hasBonus or hasGainedLevels },\n    })\n    menu:ShowAt(anchorFrame)\nend\n\n'''

ui = replace_once(
    ui,
    'function SkillsPage:GetSelectedRows()\n',
    skill_menu_methods + 'function SkillsPage:GetSelectedRows()\n',
    "selected skill rows",
)

ui = replace_once(
    ui,
    '                if button == "LeftButton" and row and row.ref then\n',
    '                if button == "RightButton" and row and row.ref then\n'
    '                    self:ShowSkillContextMenu(frame, row)\n'
    '                    return\n'
    '                end\n'
    '                if button == "LeftButton" and row and row.ref then\n',
    "skill row mouse handler",
)

ui_path.write_text(ui, encoding="utf-8")


# ---------------------------------------------------------------------------
# Static post-patch assertions
# ---------------------------------------------------------------------------
require_count(db, 'skillPermanentBonuses = normalizeProfileSkillPermanentBonuses(data.skillPermanentBonuses)', 1, "profile normalization field")
require_count(db, 'function Database.SetProfileSkillPermanentBonus', 1, "database permanent-bonus setter")
require_count(profile, 'function Profile.SetSkillPermanentBonus', 1, "profile permanent-bonus setter")
require_count(resolver, 'local permanentBonus = tonumber(permanentBonuses and permanentBonuses[entry.ref]) or 0', 1, "resolver permanent bonus")
require_count(resolver, 'local permanentBonuses = buildProfileSkillPermanentBonusMap()', 2, "resolver permanent bonus maps")
require_count(deps, 'profile.skillPermanentBonuses[deletedRef] = nil', 1, "deleted skill permanent bonus cleanup")
require_count(ui, 'function SkillsPage:ShowSkillContextMenu(anchorFrame, row)', 1, "skills context menu")
require_count(ui, 'self:ShowSkillContextMenu(frame, row)', 1, "right-click context menu hook")
require_count(ui, 'label = "Reset Bonus & Gained Levels"', 1, "combined reset menu action")
