from pathlib import Path

path = Path('client/character/profile/page_ProfileSkills.lua')
text = path.read_text(encoding='utf-8')

constant = 'local SKILL_BONUS_POPUP_KEY = "RPE_PROFILE_SKILL_PERMANENT_BONUS"\n'
if text.count(constant) != 1:
    raise SystemExit('unexpected skill bonus popup constant count')
text = text.replace(constant, '', 1)

start = text.find('function SkillsPage:EnsureSkillBonusPopup()\n')
end = text.find('function SkillsPage:EnsureSkillContextMenu()\n', start)
if start < 0 or end < 0 or end <= start:
    raise SystemExit('skill bonus popup block not found')

replacement = '''function SkillsPage:PromptPermanentSkillBonus(skillRef)\n    if not (UI.Popup and UI.Popup.ShowConfirmation) then\n        return false\n    end\n\n    local row = self:FindSkillRow(skillRef, self.AllSkillRows)\n    local skillName = tostring(row and row.name or "Skill")\n    return UI.Popup:ShowConfirmation({\n        title = "Permanent Skill Bonus",\n        width = 280,\n        message = ("Add a permanent bonus to %s."):format(skillName),\n        confirmText = "Add",\n        cancelText = "Cancel",\n        inputLabel = "Bonus",\n        inputText = "1",\n        requireInput = true,\n        onConfirm = function(spec)\n            local amount = math.floor(tonumber(spec and spec.inputText or "") or 0)\n            if amount > 0 then\n                self:AddPermanentSkillBonus(skillRef, amount)\n            end\n        end,\n    })\nend\n\n'''
text = text[:start] + replacement + text[end:]

if 'StaticPopupDialogs' in text or 'StaticPopup_Show' in text:
    raise SystemExit('static popup references remain in skills page')
if text.count('function SkillsPage:PromptPermanentSkillBonus(skillRef)') != 1:
    raise SystemExit('unexpected prompt function count')
if text.count('UI.Popup:ShowConfirmation({') < 2:
    raise SystemExit('expected existing and skill bonus popup usage')

path.write_text(text, encoding='utf-8')
