from pathlib import Path

path = Path('client/client_Skills.lua')
text = path.read_text(encoding='utf-8')

anchor = '''local function emitSkillRollCombatLog(result, skill, eventState, options)\n'''
helper = '''local function emitSkillRollChatMessage(result)\n    if not (DEFAULT_CHAT_FRAME and type(DEFAULT_CHAT_FRAME.AddMessage) == "function") then\n        return false\n    end\n\n    local message = ("%s rolls %s: %s."):format(\n        tostring(result.unitName or "Unknown"),\n        tostring(result.skillName or result.skillRef or "Skill"),\n        buildRollDetailText(result.baseRoll, result.modifier, result.total)\n    )\n    DEFAULT_CHAT_FRAME:AddMessage(message, 0.6, 0.6, 0.6)\n    return true\nend\n\n'''
if helper in text:
    raise SystemExit('chat helper already present')
if anchor not in text:
    raise SystemExit('combat-log helper anchor missing')
text = text.replace(anchor, helper + anchor, 1)

old = '''    emitSkillRollCombatLog(result, skill, eventState, options)\n    local progression = Client.SkillProgression\n'''
new = '''    emitSkillRollChatMessage(result)\n    emitSkillRollCombatLog(result, skill, eventState, options)\n    local progression = Client.SkillProgression\n'''
if old not in text:
    raise SystemExit('roll emission anchor missing')
text = text.replace(old, new, 1)

if text.count('local function emitSkillRollChatMessage(result)') != 1:
    raise SystemExit('unexpected chat helper count')
if text.count('    emitSkillRollChatMessage(result)\n') != 1:
    raise SystemExit('unexpected chat emission count')

path.write_text(text, encoding='utf-8')
