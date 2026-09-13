from pathlib import Path

path = Path('client/client_Skills.lua')
text = path.read_text(encoding='utf-8')

old_helper_anchor = '''local function isLocalPlayerEventUnit(eventState, eventUnit)\n    if type(eventUnit) ~= "table" or eventUnit.isPlayer ~= true then\n        return false\n    end\n    if type(eventState) ~= "table" or eventState.active ~= true then\n        return true\n    end\n    if type(Client.ResolveLocalEventUnit) ~= "function" then\n        return false\n    end\n\n    local localUnit = Client:ResolveLocalEventUnit(eventState)\n    local localEventId = tonumber(localUnit and localUnit.eventID) or 0\n    local requestedEventId = tonumber(eventUnit.eventID) or 0\n    return localEventId > 0 and localEventId == requestedEventId\nend\n'''

new_helper_anchor = old_helper_anchor + '''\nlocal function isLocalPlayerSkillProgressionSource(eventState, eventUnit)\n    if type(eventState) ~= "table" or eventState.active ~= true then\n        return type(eventUnit) ~= "table"\n    end\n\n    return isLocalPlayerEventUnit(eventState, eventUnit)\nend\n'''

if old_helper_anchor not in text:
    raise SystemExit('expected local-player event-unit helper not found')
if 'local function isLocalPlayerSkillProgressionSource' in text:
    raise SystemExit('progression source helper already exists')
text = text.replace(old_helper_anchor, new_helper_anchor, 1)

old_guard = '''    if type(progression) == "table"\n        and type(progression.TryGain) == "function"\n        and type(progression.GetRulesetChance) == "function"\n    then\n'''
new_guard = '''    if type(progression) == "table"\n        and type(progression.TryGain) == "function"\n        and type(progression.GetRulesetChance) == "function"\n        and isLocalPlayerSkillProgressionSource(eventState, eventUnit)\n    then\n'''

if old_guard not in text:
    raise SystemExit('expected progression guard not found')
text = text.replace(old_guard, new_guard, 1)

if text.count('local function isLocalPlayerSkillProgressionSource') != 1:
    raise SystemExit('unexpected progression helper count')
if text.count('and isLocalPlayerSkillProgressionSource(eventState, eventUnit)') != 1:
    raise SystemExit('unexpected progression guard count')

path.write_text(text, encoding='utf-8')
