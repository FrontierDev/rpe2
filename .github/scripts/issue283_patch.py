from pathlib import Path
import re

operations_path = Path('core/internal/comms/Operations.lua')
actions_path = Path('server/ui/eventmanage/page_EventManageActions.lua')

operations = operations_path.read_text(encoding='utf-8')
actions = actions_path.read_text(encoding='utf-8')

achievement_block = '''    [28] = {\n        key = "ACHIEVEMENT_ANNOUNCEMENT",\n        name = "achievement-announcement",\n        ["function"] = function(arguments, sender, distribution, target, message)\n            local client = Addon.Client\n            if not client or type(client.HandleAchievementAnnouncement) ~= "function" then\n                return false\n            end\n\n            return client:HandleAchievementAnnouncement(arguments, sender, distribution, target, message)\n        end,\n    },\n'''

skill_block = '''    [29] = {'''
if skill_block in operations or '[33] = {' in operations:
    raise SystemExit('unexpected pre-existing static opcode candidate')
if achievement_block not in operations:
    raise SystemExit('achievement opcode block not found')

new_static_block = achievement_block + '''    [33] = {\n        key = "SKILL_ROLL_REQUEST",\n        name = "skill-roll-request",\n        ["function"] = function(arguments, sender, distribution, target, message)\n            local client = Addon.Client\n            if not client or type(client.HandleSkillRollRequest) ~= "function" then\n                return false\n            end\n\n            return client:HandleSkillRollRequest(arguments, sender, distribution, target, message)\n        end,\n    },\n'''
operations = operations.replace(achievement_block, new_static_block, 1)

old_registration = '''local function registerSkillRequestOpcode()\n    if type(Operations.GetOpcode)=="function" then local existing=Operations:GetOpcode("SKILL_ROLL_REQUEST"); if existing then return existing end end\n    local opcode=28; Operations.KeyIndex=type(Operations.KeyIndex)=="table" and Operations.KeyIndex or {}; Operations.KeyIndex.SKILL_ROLL_REQUEST=opcode; Operations.Opcodes=type(Operations.Opcodes)=="table" and Operations.Opcodes or {}\n    local handler=function(args,sender,distribution,target,message) local client=Addon.Client; return type(client)=="table" and type(client.HandleSkillRollRequest)=="function" and client:HandleSkillRollRequest(args,sender,distribution,target,message) or false end\n    Operations.Opcodes[opcode]={key="SKILL_ROLL_REQUEST",name="skill-roll-request",["function"]=handler}\n    if type(Operations.Register)=="function" then Operations:Register(opcode,handler,"skill-roll-request"); local op=type(Operations.Get)=="function" and Operations:Get(opcode) or nil; if type(op)=="table" then op.key="SKILL_ROLL_REQUEST" end else Operations.Registry=type(Operations.Registry)=="table" and Operations.Registry or {}; Operations.Registry[opcode]=Operations.Opcodes[opcode] end\n    return opcode\nend\nlocal SKILL_REQUEST_OPCODE=registerSkillRequestOpcode()\n'''
new_registration = '''local SKILL_REQUEST_OPCODE = type(Operations.GetOpcode) == "function"\n    and Operations:GetOpcode("SKILL_ROLL_REQUEST")\n    or nil\n'''
if old_registration not in actions:
    raise SystemExit('dynamic skill request opcode registration not found')
actions = actions.replace(old_registration, new_registration, 1)

if operations.count('key = "ACHIEVEMENT_ANNOUNCEMENT"') != 1:
    raise SystemExit('unexpected achievement key count')
if operations.count('key = "SKILL_ROLL_REQUEST"') != 1:
    raise SystemExit('unexpected skill request key count')
if '[28] = {' not in operations or '[33] = {' not in operations:
    raise SystemExit('expected static opcodes missing')
if 'registerSkillRequestOpcode' in actions:
    raise SystemExit('dynamic registration function remains')
if 'Operations.Opcodes[' in actions or 'Operations.KeyIndex.' in actions:
    raise SystemExit('event manager still mutates operation registry')
if actions.count('Operations:GetOpcode("SKILL_ROLL_REQUEST")') != 1:
    raise SystemExit('event manager does not resolve the static skill opcode exactly once')

operations_path.write_text(operations, encoding='utf-8')
actions_path.write_text(actions, encoding='utf-8')
