from pathlib import Path


def replace_once(text, old, new, label):
    if old not in text:
        raise SystemExit(f"missing anchor: {label}")
    if text.count(old) != 1:
        raise SystemExit(f"unexpected anchor count for {label}: {text.count(old)}")
    return text.replace(old, new, 1)


rules_path = Path("core/internal/ruleset/Rules.lua")
rules = rules_path.read_text(encoding="utf-8")

anchor = '            { key = "weapon_skill_gain_chance_on_hit", label = "Weapon Skill Gain Chance On Hit", type = "text", default = "0", description = "Percent chance to gain weapon skill progression from a valid hit." },\n'
rule = '            { key = "allow_permanent_skill_bonuses_after_setup", label = "Allow Permanent Skill Bonuses After Setup", type = "checkbox", default = false, description = "Allow players to manually add permanent skill bonuses from the Skills window after character setup." },\n'
rules = replace_once(rules, anchor, rule + anchor, "skills progression rules")
rules_path.write_text(rules, encoding="utf-8")


ui_path = Path("client/character/profile/page_ProfileSkills.lua")
ui = ui_path.read_text(encoding="utf-8")

method_anchor = '''function SkillsPage:AddPermanentSkillBonus(skillRef, amount)\n    local normalizedAmount = math.max(0, math.floor(tonumber(amount) or 0))\n'''
method_replacement = '''function SkillsPage:AddPermanentSkillBonus(skillRef, amount)\n    if getSkillRuleValue("allow_permanent_skill_bonuses_after_setup", false) ~= true then\n        return false\n    end\n\n    local normalizedAmount = math.max(0, math.floor(tonumber(amount) or 0))\n'''
ui = replace_once(ui, method_anchor, method_replacement, "permanent bonus mutation guard")

prompt_anchor = '''function SkillsPage:PromptPermanentSkillBonus(skillRef)\n    if not (UI.Popup and UI.Popup.ShowConfirmation) then\n        return false\n    end\n'''
prompt_replacement = '''function SkillsPage:PromptPermanentSkillBonus(skillRef)\n    if getSkillRuleValue("allow_permanent_skill_bonuses_after_setup", false) ~= true then\n        return false\n    end\n    if not (UI.Popup and UI.Popup.ShowConfirmation) then\n        return false\n    end\n'''
ui = replace_once(ui, prompt_anchor, prompt_replacement, "permanent bonus prompt guard")

menu_anchor = '''    local hasBonus = permanentBonus > 0\n    local hasGainedLevels = storedLevel > 0\n\n    self.ContextMenuSkillRef = row.ref\n'''
menu_replacement = '''    local hasBonus = permanentBonus > 0\n    local hasGainedLevels = storedLevel > 0\n    local canAddPermanentBonus = getSkillRuleValue("allow_permanent_skill_bonuses_after_setup", false) == true\n\n    self.ContextMenuSkillRef = row.ref\n'''
ui = replace_once(ui, menu_anchor, menu_replacement, "context menu availability")

item_anchor = '        { label = "Add Permanent Bonus...", value = "add-permanent-bonus" },\n'
item_replacement = '        { label = "Add Permanent Bonus...", value = "add-permanent-bonus", enabled = canAddPermanentBonus },\n'
ui = replace_once(ui, item_anchor, item_replacement, "context menu add item")

ui_path.write_text(ui, encoding="utf-8")
