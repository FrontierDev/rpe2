from pathlib import Path

path = Path('client/ui/windows/window_SetupWizard.lua')
text = path.read_text(encoding='utf-8')
old = '''        local allocatedCount = 0\n        for index = 1, #(self:GetSetupSkillRows() or {}) do\n            local row = self:GetSetupSkillRows()[index]\n            local amount = math.max(0, math.floor(tonumber(selection.skillPermanentBonuses and selection.skillPermanentBonuses[row.ref]) or 0))\n'''
new = '''        local allocatedCount = 0\n        local setupSkillRows = self:GetSetupSkillRows() or {}\n        for index = 1, #setupSkillRows do\n            local row = setupSkillRows[index]\n            local amount = math.max(0, math.floor(tonumber(selection.skillPermanentBonuses and selection.skillPermanentBonuses[row.ref]) or 0))\n'''
if text.count(old) != 1:
    raise SystemExit(f'expected finalize loop once, found {text.count(old)}')
path.write_text(text.replace(old, new, 1), encoding='utf-8')
