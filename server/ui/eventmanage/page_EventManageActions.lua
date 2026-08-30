local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Server.UI = Addon.Server.UI or {}
Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}
Addon.Utils = Addon.Utils or {}

local Server = Addon.Server
local Client = Addon.Client
local ServerUI = Addon.Server.UI
local Comms = Addon.Internal.Comms or {}
local Operations = Comms.Operations or {}
local Registry = Addon.Internal.Registry or {}
local Ruleset = Addon.Internal.Ruleset or {}
local Common = Addon.Utils.Common or {}
local UI = Addon.UI or {}
local C = UI.Constants or {}

ServerUI.EventManage = ServerUI.EventManage or {}
local EventManage = ServerUI.EventManage

local DEFAULT_AURA_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local DEFAULT_SKILL_ICON = "Interface\\Icons\\Ability_Hunter_FocusedAim"
local SUCCESS_COLOR = "ff43b35c"
local FAILURE_COLOR = "ffd94c4c"
local CONTENT_WIDTH = 480
local CONTROL_HEIGHT = 20
local DROPDOWN_HEIGHT = 18
local SPACING = 5

local function trim(v) return tostring(v or ""):gsub("^%s+", ""):gsub("%s+$", "") end
local function finite(v)
    local n = tonumber(v)
    return n ~= nil and n == n and n ~= math.huge and n ~= -math.huge
end
local function normName(v)
    return type(Common.NormalizeName) == "function" and Common.NormalizeName(v) or tostring(v or "")
end
local function threshold(v)
    if v == nil or trim(v) == "" then return nil, true end
    if not finite(v) then return nil, false end
    return math.floor(tonumber(v)), true
end
local function findUnit(state, eventId)
    local id = math.floor(tonumber(eventId) or 0)
    if type(state) ~= "table" or id <= 0 then return nil end
    for i = 1, #(state.units or {}) do
        local unit = state.units[i]
        if type(unit) == "table" and math.floor(tonumber(unit.eventID) or 0) == id then return unit end
    end
end
local function clientState() return type(Client.GetState) == "function" and Client:GetState() or Client.State end
local function clientEvent() return type(Client.GetEventState) == "function" and Client:GetEventState() or Client.EventState end
local function serverEvent() return type(Server.GetEventState) == "function" and Server:GetEventState() or Server.EventState end
local function refreshActions()
    local em = Addon.Server and Addon.Server.UI and Addon.Server.UI.EventManage
    if type(em) == "table" and type(em.IsWindowVisible) == "function" and em:IsWindowVisible()
        and type(em.IsActionsPageActive) == "function" and em:IsActionsPageActive()
        and type(em.RefreshActionsPage) == "function"
    then return em:RefreshActionsPage() == true end
    return false
end
local function actionContext()
    local se, ce, cs = serverEvent(), clientEvent(), clientState()
    if type(Server.IsActive) == "function" and not Server:IsActive() then return nil, "server-inactive" end
    if type(se) ~= "table" or se.active ~= true then return nil, "event-inactive" end
    if type(Server.IsEventUnitsReady) == "function" and not Server:IsEventUnitsReady() then return nil, "event-not-ready" end
    if type(cs) ~= "table" or cs.active ~= true then return nil, "client-inactive" end
    if type(ce) ~= "table" or ce.active ~= true or tostring(ce.id or "") ~= tostring(se.id or "") then return nil, "event-state-mismatch" end
    if type(Client.IsLocalEventHost) ~= "function" or not Client:IsLocalEventHost(ce) then return nil, "not-host" end
    if type(Client.CanPerformEventAction) == "function" then
        local ok, reason = Client:CanPerformEventAction(ce, "event-manager-action")
        if ok ~= true then return nil, reason or "event-action-blocked" end
    end
    return { serverEventState = se, clientEventState = ce, clientState = cs }
end
local function actionUnit(eventId)
    local ctx, reason = actionContext()
    if not ctx then return nil, nil, nil, reason end
    local su, cu = findUnit(ctx.serverEventState, eventId), findUnit(ctx.clientEventState, eventId)
    if type(su) ~= "table" or type(cu) ~= "table" then return nil, nil, ctx, "missing-unit" end
    return su, cu, ctx
end
local function parseRef(ref)
    local datasetId, entryId = trim(ref):match("^([^:]+):(.+)$")
    if not datasetId or not entryId or datasetId == "" or entryId == "" then return nil, nil end
    return datasetId, entryId
end
local function resolveDef(ref, key)
    local datasetId, entryId = parseRef(ref)
    if not datasetId then return nil, nil end
    local datasets = type(Registry.GetActivatedDatasets) == "function" and Registry:GetActivatedDatasets() or {}
    for di = 1, #datasets do
        local ds = datasets[di]
        if tostring(ds and ds.id or "") == datasetId then
            for ei = 1, #((ds and ds[key]) or {}) do
                local e = ds[key][ei]
                if tostring(e and e.id or "") == entryId then return ds, e end
            end
            return ds, nil
        end
    end
end

local function healthRef(ctx)
    local ref = trim(ctx and ctx.serverEventState and ctx.serverEventState.healthResourceRef)
    if ref == "" then ref = trim(ctx and ctx.clientEventState and ctx.clientEventState.healthResourceRef) end
    if ref ~= "" then return ref end
    local ruleset = type(Ruleset.GetActiveRuleset) == "function" and Ruleset.GetActiveRuleset() or nil
    local def = type(Ruleset.GetRulesetRuleDefinition) == "function" and Ruleset.GetRulesetRuleDefinition("resources", "health_stat") or nil
    ref = def and type(Ruleset.GetRulesetRuleValue) == "function" and trim(Ruleset.GetRulesetRuleValue(ruleset, "resources", def)) or ""
    return ref ~= "" and ref or nil
end
local function resource(unit, ref)
    for i = 1, #((unit and unit.resources) or {}) do
        local e = unit.resources[i]
        if type(e) == "table" and tostring(e.resourceRef or "") == ref then return e end
    end
end
local function healthState(su, cu, ctx)
    local ref = healthRef(ctx)
    if not ref then return nil, "missing-health-resource" end
    local e = resource(su, ref) or resource(cu, ref)
    if not e then return nil, "missing-health-entry" end
    local max = tonumber(e.maxValue); local cur = tonumber(e.currentValue)
    if cur == nil then cur = max end; if max == nil then max = cur end
    max = math.max(0, tonumber(max) or 0); cur = math.max(0, math.min(max, tonumber(cur) or 0))
    return { resourceRef = ref, currentValue = cur, maxValue = max, isDead = cur <= 0 }
end

function Server:CanUseEventManagerActions() local ctx, reason = actionContext(); return ctx ~= nil, reason end
function Server:GetEventManagerHealthState(eventId)
    local su, cu, ctx, reason = actionUnit(eventId); if not su then return nil, reason end
    local hs, why = healthState(su, cu, ctx); if not hs then return nil, why end
    hs.eventId = math.floor(tonumber(su.eventID) or 0); hs.unitName = tostring(su.name or cu.name or "Unknown"); return hs
end
function Server:ApplyEventManagerHealthAction(eventId, action, amount)
    local su, cu, ctx, reason = actionUnit(eventId); if not su then return false, reason end
    local hs, why = healthState(su, cu, ctx); if not hs then return false, why end
    local key, delta = string.lower(trim(action)), 0
    if key == "damage" or key == "heal" then
        if hs.isDead then return false, "target-dead" end
        if not finite(amount) or tonumber(amount) <= 0 then return false, "invalid-amount" end
        local n = tonumber(amount)
        delta = key == "damage" and -math.min(n, hs.currentValue) or math.min(n, math.max(0, hs.maxValue - hs.currentValue))
    elseif key == "kill" then
        if hs.isDead then return false, "already-dead" end; delta = -hs.currentValue
    elseif key == "resurrect" then
        if not hs.isDead then return false, "already-alive" end
        if hs.maxValue <= 0 then return false, "invalid-health-maximum" end; delta = hs.maxValue
    else return false, "invalid-action" end
    if delta == 0 then return false, "no-change" end
    local targetId = math.floor(tonumber(su.eventID) or 0)
    local queued = false
    if key == "resurrect" then
        if type(Client.SendClientResources) ~= "function" then return false, "resource-sync-unavailable" end
        local resources, replaced = {}, false
        for i = 1, #(cu.resources or {}) do
            local e = cu.resources[i]
            if type(e) == "table" then
                local copy = { resourceRef = tostring(e.resourceRef or ""), currentValue = tonumber(e.currentValue ~= nil and e.currentValue or e.maxValue) or 0, maxValue = tonumber(e.maxValue ~= nil and e.maxValue or e.currentValue) or 0 }
                if copy.resourceRef == hs.resourceRef then copy.currentValue, copy.maxValue, replaced = hs.maxValue, hs.maxValue, true end
                resources[#resources + 1] = copy
            end
        end
        if not replaced then return false, "missing-health-entry" end
        queued = Client:SendClientResources(ctx.clientState, "event-manager-resurrect", Common.GetPlayerName and Common.GetPlayerName() or nil, resources, targetId) == true
    else
        if type(Client.QueueClientResourceDeltas) ~= "function" then return false, "resource-sync-unavailable" end
        queued = Client:QueueClientResourceDeltas(ctx.clientState, "event-manager-" .. key, {{ resourceRef = hs.resourceRef, delta = delta, maxValue = hs.maxValue, currentValue = math.max(0, math.min(hs.maxValue, hs.currentValue + delta)) }}, targetId, { allowLocalEchoApply = true, immediate = true, scope = "reaction" }) == true
    end
    if not queued then return false, key == "resurrect" and "resource-sync-rejected" or "resource-delta-rejected" end
    return true, { action = key, eventId = targetId, resourceRef = hs.resourceRef, delta = delta, previousValue = hs.currentValue, nextValue = math.max(0, math.min(hs.maxValue, hs.currentValue + delta)), maxValue = hs.maxValue }
end

local function auraManager() return Client.Spellcasting and Client.Spellcasting.AuraManager or nil end
local function auraName(am, entry)
    local def = entry.definition
    if type(am.ResolveAuraDefinition) == "function" then local _, resolved = am:ResolveAuraDefinition(entry.auraRef, {datasetId=entry.datasetId}); if type(resolved)=="table" then def=resolved end end
    local name = trim(def and def.name); return name ~= "" and name or tostring(entry.auraRef or "Aura"), def
end
function Server:ApplyEventManagerAura(eventId, auraRef)
    local _, cu, ctx, reason = actionUnit(eventId); if not cu then return false, reason end
    local ds, aura = resolveDef(auraRef, "auras"); if not ds or not aura then return false, "missing-aura" end
    local am = auraManager(); if type(am) ~= "table" or type(am.ApplyAuraFromContext) ~= "function" then return false, "aura-manager-unavailable" end
    local ok, entry = am:ApplyAuraFromContext(Client, {eventState=ctx.clientEventState,casterUnit=cu,targetUnit=cu,dataset=ds,datasetId=ds.id}, tostring(auraRef), nil, nil, nil)
    if ok ~= true then return false, "aura-apply-rejected" end; refreshActions(); return true, entry
end
function Server:ListEventManagerActiveAuras(eventId)
    local _, cu, ctx = actionUnit(eventId); if not cu or not ctx then return {} end
    local am = auraManager(); if type(am) ~= "table" or type(am.GetEventAuraBucket) ~= "function" then return {} end
    local bucket = am:GetEventAuraBucket(Client, ctx.clientEventState.id, false); local rows, targetId = {}, math.floor(tonumber(cu.eventID) or 0)
    for key, e in pairs(type(bucket)=="table" and bucket.byKey or {}) do
        if type(e)=="table" and math.floor(tonumber(e.targetEventId) or 0)==targetId and (tonumber(e.stacks) or 0)>0 then
            local name, def = auraName(am, e); local stacks = math.max(1, math.floor(tonumber(e.stacks) or 1))
            rows[#rows+1] = { auraKey=tostring(e.auraKey or key or ""), auraRef=tostring(e.auraRef or ""), name=name, icon=trim(def and def.icon)~="" and tostring(def.icon) or DEFAULT_AURA_ICON, stacks=stacks, casterEventId=math.floor(tonumber(e.casterEventId) or 0), targetEventId=targetId, turnsRemaining=tonumber(e.turnsRemaining), label=stacks>1 and ("%s x%d"):format(name,stacks) or name }
        end
    end
    table.sort(rows,function(a,b) local an,bn=string.lower(tostring(a.name or "")),string.lower(tostring(b.name or "")); return an==bn and tostring(a.auraKey or "")<tostring(b.auraKey or "") or an<bn end); return rows
end
function Server:RemoveEventManagerAura(eventId, auraKey)
    local _, cu, ctx, reason = actionUnit(eventId); if not cu then return false, reason end
    local am=auraManager(); if type(am)~="table" or type(am.GetEventAuraBucket)~="function" or type(am.DispelAuraFromContext)~="function" then return false,"aura-manager-unavailable" end
    local bucket=am:GetEventAuraBucket(Client,ctx.clientEventState.id,false); local e=type(bucket)=="table" and type(bucket.byKey)=="table" and bucket.byKey[tostring(auraKey or "")] or nil; local targetId=math.floor(tonumber(cu.eventID) or 0)
    if type(e)~="table" or math.floor(tonumber(e.targetEventId) or 0)~=targetId then return false,"missing-active-aura" end
    if am:DispelAuraFromContext(Client,{eventState=ctx.clientEventState},e.auraRef,e.casterEventId,e.targetEventId,e)~=true then return false,"aura-remove-rejected" end
    refreshActions(); return true
end

local function registerSkillRequestOpcode()
    if type(Operations.GetOpcode)=="function" then local existing=Operations:GetOpcode("SKILL_ROLL_REQUEST"); if existing then return existing end end
    local opcode=28; Operations.KeyIndex=type(Operations.KeyIndex)=="table" and Operations.KeyIndex or {}; Operations.KeyIndex.SKILL_ROLL_REQUEST=opcode; Operations.Opcodes=type(Operations.Opcodes)=="table" and Operations.Opcodes or {}
    local handler=function(args,sender,distribution,target,message) local client=Addon.Client; return type(client)=="table" and type(client.HandleSkillRollRequest)=="function" and client:HandleSkillRollRequest(args,sender,distribution,target,message) or false end
    Operations.Opcodes[opcode]={key="SKILL_ROLL_REQUEST",name="skill-roll-request",["function"]=handler}
    if type(Operations.Register)=="function" then Operations:Register(opcode,handler,"skill-roll-request"); local op=type(Operations.Get)=="function" and Operations:Get(opcode) or nil; if type(op)=="table" then op.key="SKILL_ROLL_REQUEST" end else Operations.Registry=type(Operations.Registry)=="table" and Operations.Registry or {}; Operations.Registry[opcode]=Operations.Opcodes[opcode] end
    return opcode
end
local SKILL_REQUEST_OPCODE=registerSkillRequestOpcode()
local function controllerName(unit)
    local name=normName(unit and unit.controllerID); if name~="" then return name end; name=normName(unit and unit.ownerID); if name~="" then return name end; return unit and unit.isPlayer==true and normName(unit.name) or ""
end
local function requestId(eventId,targetId) Server.SkillRollRequestSequence=math.max(0,math.floor(tonumber(Server.SkillRollRequestSequence) or 0))+1; return table.concat({tostring(eventId or ""),tostring(targetId),tostring(Server.SkillRollRequestSequence)},":") end
local function num(v) local n=tonumber(v) or 0; if n==math.floor(n) then return tostring(math.floor(n)) end; return (("%.2f"):format(n):gsub("0+$",""):gsub("%.$","")) end
local function detail(base,mod,total) mod=tonumber(mod) or 0; return mod<0 and ("%s - %s = %s"):format(num(base),num(math.abs(mod)),num(total)) or ("%s + %s = %s"):format(num(base),num(mod),num(total)) end
function Client:RollEventManagerSkillRequest(skillRef, options)
    if type(self.RollSkill)~="function" then return nil,"skill-roll-unavailable" end
    local values=type(options)=="table" and options or {}; local limit,valid=threshold(values.successThreshold); if not valid then return nil,"invalid-success-threshold" end
    if limit==nil then return self:RollSkill(skillRef,values) end
    local opts={}; for k,v in pairs(values) do opts[k]=v end; opts.emitCombatLog=false
    local result,reason=self:RollSkill(skillRef,opts); if not result then return nil,reason end
    result.successThreshold=limit; result.isSuccess=(tonumber(result.total) or 0)>=limit
    local icon=trim(result.skillIcon); if icon=="" then icon=DEFAULT_SKILL_ICON end
    local entry={eventId=tostring((opts.eventState or clientEvent() or {}).id or ""),entryType="status",casterDisplayName=tostring(result.unitName or "Unknown"),targetDisplayName=("rolls %s:"):format(tostring(result.skillName or result.skillRef or "Skill")),targetCount=1,iconTexture=icon,spellIconTexture=icon,labelText=tostring(result.skillName or result.skillRef or "Skill"),detailText=detail(result.baseRoll,result.modifier,result.total),accentColor=result.isSuccess and SUCCESS_COLOR or FAILURE_COLOR}
    if type(self.QueueCombatLogEntryEmission)=="function" then self:QueueCombatLogEntryEmission(entry) elseif type(self.EmitCombatLogEntry)=="function" then self:EmitCombatLogEntry(entry) end
    return result
end
function Server:RequestEventManagerSkillRoll(eventId, skillRef, successThreshold)
    local su,cu,ctx,reason=actionUnit(eventId); if not su then return false,reason end
    local _,skill=resolveDef(skillRef,"skills"); if type(skill)~="table" or skill.rollable~=true or tostring(skill.skillType or "noncombat")~="noncombat" then return false,"missing-or-unrollable-skill" end
    local limit,valid=threshold(successThreshold); if not valid then return false,"invalid-success-threshold" end
    local rid=requestId(ctx.clientEventState.id,math.floor(tonumber(su.eventID) or 0)); local recipient=controllerName(su); local host=normName(Common.GetPlayerName and Common.GetPlayerName() or nil)
    if recipient=="" or recipient==host then local result,why=Client:RollEventManagerSkillRequest(skillRef,{eventState=ctx.clientEventState,eventUnit=cu,source="event-manager-request",requestId=rid,successThreshold=limit}); return result~=nil,result or why end
    if not SKILL_REQUEST_OPCODE or type(Comms.SendMessage)~="function" then return false,"skill-roll-request-unavailable" end
    local sent=Comms:SendMessage("WHISPER",SKILL_REQUEST_OPCODE,{tostring(ctx.clientEventState.id or ""),tostring(math.floor(tonumber(su.eventID) or 0)),tostring(skillRef or ""),rid,limit~=nil and tostring(limit) or ""},recipient,{opcode=SKILL_REQUEST_OPCODE,scope="server"})
    if sent~=true then return false,"request-send-failed" end; return true,{requestId=rid,recipient=recipient,targetEventId=math.floor(tonumber(su.eventID) or 0),successThreshold=limit}
end
Client.ProcessedSkillRollRequestIds=Client.ProcessedSkillRollRequestIds or {}
function Client:HandleSkillRollRequest(args,sender)
    local ev=clientEvent(); local eventId=tostring(args and args[1] or ""); local targetId=math.floor(tonumber(args and args[2]) or 0); local skillRef=tostring(args and args[3] or ""); local rid=tostring(args and args[4] or ""); local limit,valid=threshold(args and args[5])
    if type(ev)~="table" or ev.active~=true or eventId=="" or eventId~=tostring(ev.id or "") or targetId<=0 or skillRef=="" or rid=="" or not valid or normName(sender)~=normName(ev.hostName) then return false end
    if type(self.CanPerformEventAction)=="function" and self:CanPerformEventAction(ev,"event-manager-skill-request")~=true then return false end
    local requested=findUnit(ev,targetId); if not requested then return false end
    local authorized=nil
    if requested.isPlayer==true and type(self.ResolveLocalEventUnit)=="function" then local unit=self:ResolveLocalEventUnit(ev); if math.floor(tonumber(unit and unit.eventID) or 0)==targetId then authorized=unit end
    elseif requested.isPlayer~=true and type(self.ResolveControlledEventUnit)=="function" then local unit=self:ResolveControlledEventUnit(ev); if math.floor(tonumber(unit and unit.eventID) or 0)==targetId then authorized=unit end end
    if not authorized then return false end
    local key=eventId.."\31"..rid; if self.ProcessedSkillRollRequestIds[key] then return false end
    if type(self.RollEventManagerSkillRequest)~="function" then return false end; self.ProcessedSkillRollRequestIds[key]=true
    return self:RollEventManagerSkillRequest(skillRef,{eventState=ev,eventUnit=authorized,source="event-manager-request",requestId=rid,successThreshold=limit})~=nil
end

local function hookRefresh(name)
    local original=Client[name]; if type(original)~="function" then return end
    Client[name]=function(self,...) local result=original(self,...); if result==true then refreshActions() end; return result end
end
if Client._eventManagerActionRefreshHooksInstalled~=true then
    for _,name in ipairs({"HandleResource","HandleResourceDelta","HandleResourceDeltaBatch","HandleAuraApply","HandleAuraApplyBatch","HandleAuraDispel","HandleAuraDispelBatch"}) do hookRefresh(name) end
    Client._eventManagerActionRefreshHooksInstalled=true
end

-- Actions page UI ------------------------------------------------------------
local function text(parent,name,value,width,color)
    return UI.CreateText(parent,name,value,{width=width or CONTENT_WIDTH,height=18,fontFile=(C.FontFiles and C.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",fontSize=(C.FontSizes and C.FontSizes.Body) or 8,textColor=UI.ResolveColor(nil,color or "text.secondary"),justifyH="LEFT",justifyV="MIDDLE",wordWrap=false})
end
local function row(parent,name) return UI.CreateLayout(UI.HorizontalLayoutGroup,parent,name,{width=CONTENT_WIDTH,height=CONTROL_HEIGHT,spacing=SPACING,autoSize=false,fitChildrenWidth=false,fitChildrenHeight=false}) end
local function enable(control,value) if control and control.SetEnabled then control:SetEnabled(value==true) end end
local function has(items,value) value=tostring(value or ""); for i=1,#(items or {}) do if tostring(items[i].value or "")==value then return true end end; return false end
local function sync(dropdown,items,value) value=tostring(value or ""); if not has(items,value) then value="" end; if dropdown.SetItems then dropdown:SetItems(items) end; if dropdown.SetSelectedValue then dropdown:SetSelectedValue(value,true) end; return value end
function EventManage:BuildActionUnitItems()
    local items={{label="Select Unit",value=""}}; local rows=self.BuildUnitRows and self:BuildUnitRows() or {}
    for i=1,#rows do local r=rows[i]; local id=math.floor(tonumber(r and r.eventID) or 0); if id>0 then items[#items+1]={label=("%s (#%d)"):format(trim(r.name)~="" and trim(r.name) or "Unnamed Unit",id),value=tostring(id)} end end; return items
end
local function definitionItems(key,predicate,empty)
    local items,rows={{label=empty,value=""}},{}; local datasets=type(Registry.GetActivatedDatasets)=="function" and Registry:GetActivatedDatasets() or {}
    for di=1,#datasets do local ds=datasets[di]; local dsid=tostring(ds and ds.id or ""); for ei=1,#((ds and ds[key]) or {}) do local e=ds[key][ei]; if dsid~="" and e and e.id and (not predicate or predicate(e)) then rows[#rows+1]={label=trim(e.name)~="" and trim(e.name) or tostring(e.id),value=("%s:%s"):format(dsid,tostring(e.id)),icon=e.icon} end end end
    table.sort(rows,function(a,b)return string.lower(a.label)<string.lower(b.label) end); for i=1,#rows do items[#items+1]=rows[i] end; return items
end
function EventManage:BuildActionAuraItems() return definitionItems("auras",nil,"Select Aura") end
function EventManage:BuildActionSkillItems() return definitionItems("skills",function(s)return s.rollable==true and tostring(s.skillType or "noncombat")=="noncombat" end,"Select Skill") end
function EventManage:BuildActionActiveAuraItems(eventId)
    local items={{label="Select Active Aura",value=""}}; local rows=type(Server.ListEventManagerActiveAuras)=="function" and Server:ListEventManagerActiveAuras(eventId) or {}
    for i=1,#rows do local r=rows[i]; if trim(r.auraKey)~="" then items[#items+1]={label=tostring(r.label or r.name or r.auraRef or "Aura"),value=tostring(r.auraKey),icon=r.icon} end end; return items
end
function EventManage:SetActionsStatus(value) if self.ActionsStatusText and self.ActionsStatusText.SetText then self.ActionsStatusText:SetText(tostring(value or "")) end end
function EventManage:IsActionsPageActive() local tab=self.Window and self.Window.GetActiveTab and self.Window:GetActiveTab() or nil; return tab and tab.name=="page_Actions" end
function EventManage:RefreshActionsPage()
    if not self.ActionsRootLayout then return false end
    local ready=type(Server.CanUseEventManagerActions)=="function" and Server:CanUseEventManagerActions()==true; local units=self:BuildActionUnitItems()
    self.ActionsHealthUnitEventId=sync(self.ActionsHealthUnitDropdown,units,self.ActionsHealthUnitEventId); self.ActionsAuraUnitEventId=sync(self.ActionsAuraUnitDropdown,units,self.ActionsAuraUnitEventId); self.ActionsSkillUnitEventId=sync(self.ActionsSkillUnitDropdown,units,self.ActionsSkillUnitEventId)
    self.ActionsAuraRef=sync(self.ActionsAuraDropdown,self:BuildActionAuraItems(),self.ActionsAuraRef); self.ActionsSkillRef=sync(self.ActionsSkillDropdown,self:BuildActionSkillItems(),self.ActionsSkillRef)
    local healthId=tonumber(self.ActionsHealthUnitEventId) or 0; local hs=ready and healthId>0 and type(Server.GetEventManagerHealthState)=="function" and Server:GetEventManagerHealthState(healthId) or nil; local amt=self.ActionsHealthAmountInput and self.ActionsHealthAmountInput:GetText() or ""; local validAmt=finite(amt) and tonumber(amt)>0; local health=ready and type(hs)=="table"
    enable(self.ActionsHealthUnitDropdown,ready); enable(self.ActionsHealthAmountInput,ready); enable(self.ActionsDamageButton,health and not hs.isDead and validAmt); enable(self.ActionsHealButton,health and not hs.isDead and validAmt and hs.currentValue<hs.maxValue); enable(self.ActionsKillButton,health and not hs.isDead and hs.currentValue>0); enable(self.ActionsResurrectButton,health and hs.isDead and hs.maxValue>0)
    local auraId=tonumber(self.ActionsAuraUnitEventId) or 0; local active=ready and auraId>0 and self:BuildActionActiveAuraItems(auraId) or {{label="Select Active Aura",value=""}}; self.ActionsAuraInstanceKey=sync(self.ActionsActiveAuraDropdown,active,self.ActionsAuraInstanceKey); enable(self.ActionsAuraUnitDropdown,ready); enable(self.ActionsAuraDropdown,ready); enable(self.ActionsApplyAuraButton,ready and auraId>0 and trim(self.ActionsAuraRef)~=""); enable(self.ActionsActiveAuraDropdown,ready and #active>1); enable(self.ActionsRemoveAuraButton,ready and auraId>0 and trim(self.ActionsAuraInstanceKey)~="")
    local skillId=tonumber(self.ActionsSkillUnitEventId) or 0; local thresholdText=self.ActionsSkillSuccessInput and trim(self.ActionsSkillSuccessInput:GetText()) or ""; local thresholdValid=thresholdText=="" or finite(thresholdText); enable(self.ActionsSkillUnitDropdown,ready); enable(self.ActionsSkillDropdown,ready); enable(self.ActionsSkillSuccessInput,ready); enable(self.ActionsRequestSkillButton,ready and skillId>0 and trim(self.ActionsSkillRef)~="" and thresholdValid)
    if not ready then self:SetActionsStatus("Actions are unavailable until the Event is active and ready on the host.") end; return true
end
if EventManage._actionsRefreshRoutingInstalled~=true then local base=EventManage.RefreshActivePage; EventManage.RefreshActivePage=function(self) if self:IsActionsPageActive() then return self:RefreshActionsPage() end; return type(base)=="function" and base(self) or false end; EventManage._actionsRefreshRoutingInstalled=true end
function EventManage:BuildActionsPage(page)
    if self.ActionsRootLayout then return self.ActionsRootLayout end
    self.ActionsPage=page; local root=UI.CreateLayout(UI.VerticalLayoutGroup,page,"RPEServerEventManageActionsRootLayout",{width=CONTENT_WIDTH,spacing=6,paddingLeft=0,paddingTop=0,fitChildrenWidth=true,fitChildrenHeight=false}); self.ActionsRootLayout=root; root:SetPoint("TOPLEFT",page,"TOPLEFT",0,0); root:SetPoint("TOPRIGHT",page,"TOPRIGHT",0,0)
    root:AddChild(text(root:GetFrame(),"RPEServerEventManageActionsHealthHeader","Health / Life State",CONTENT_WIDTH,"warning"))
    local healthRow=row(root:GetFrame(),"RPEServerEventManageActionsHealthRow"); self.ActionsHealthUnitDropdown=UI.CreateDropdown(healthRow:GetFrame(),"RPEServerEventManageActionsHealthUnitDropdown",{width=120,height=DROPDOWN_HEIGHT,items={},selectedValue="",onValueChanged=function(v)self.ActionsHealthUnitEventId=tostring(v or "");self:RefreshActionsPage()end});healthRow:AddChild(self.ActionsHealthUnitDropdown);healthRow:AddChild(text(healthRow:GetFrame(),"RPEServerEventManageActionsAmountLabel","Amount",42));self.ActionsHealthAmountInput=UI.CreateTextInput(healthRow:GetFrame(),"RPEServerEventManageActionsHealthAmountInput",{width=55,height=CONTROL_HEIGHT,text="1",justifyH="CENTER"});self.ActionsHealthAmountInput:SetScript("OnTextChanged",function()self:RefreshActionsPage()end);healthRow:AddChild(self.ActionsHealthAmountInput)
    local function healthButton(field,suffix,label,width,key,withAmount) self[field]=UI.CreateButton(healthRow:GetFrame(),"RPEServerEventManageActions"..suffix,label,width,function()local ok,result=Server:ApplyEventManagerHealthAction(self.ActionsHealthUnitEventId,key,withAmount and self.ActionsHealthAmountInput:GetText() or nil);self:SetActionsStatus(ok and (label.." queued.") or (label.." failed: "..tostring(result or "unknown")));self:RefreshActionsPage()end);healthRow:AddChild(self[field]) end
    healthButton("ActionsDamageButton","DamageButton","Damage",55,"damage",true);healthButton("ActionsHealButton","HealButton","Heal",45,"heal",true);healthButton("ActionsKillButton","KillButton","Kill",42,"kill",false);healthButton("ActionsResurrectButton","ResurrectButton","Resurrect",67,"resurrect",false);root:AddChild(healthRow)
    root:AddChild(text(root:GetFrame(),"RPEServerEventManageActionsAuraHeader","Auras",CONTENT_WIDTH,"warning"));local auraRow=row(root:GetFrame(),"RPEServerEventManageActionsAuraApplyRow");self.ActionsAuraUnitDropdown=UI.CreateDropdown(auraRow:GetFrame(),"RPEServerEventManageActionsAuraUnitDropdown",{width=130,height=DROPDOWN_HEIGHT,items={},selectedValue="",onValueChanged=function(v)self.ActionsAuraUnitEventId=tostring(v or "");self.ActionsAuraInstanceKey="";self:RefreshActionsPage()end});auraRow:AddChild(self.ActionsAuraUnitDropdown);self.ActionsAuraDropdown=UI.CreateDropdown(auraRow:GetFrame(),"RPEServerEventManageActionsAuraDropdown",{width=220,height=DROPDOWN_HEIGHT,items={},selectedValue="",onValueChanged=function(v)self.ActionsAuraRef=tostring(v or "");self:RefreshActionsPage()end});auraRow:AddChild(self.ActionsAuraDropdown);self.ActionsApplyAuraButton=UI.CreateButton(auraRow:GetFrame(),"RPEServerEventManageActionsApplyAuraButton","Apply Aura",88,function()local ok,r=Server:ApplyEventManagerAura(self.ActionsAuraUnitEventId,self.ActionsAuraRef);self:SetActionsStatus(ok and "Aura application queued." or ("Apply Aura failed: "..tostring(r or "unknown")));self:RefreshActionsPage()end);auraRow:AddChild(self.ActionsApplyAuraButton);root:AddChild(auraRow)
    local removeRow=row(root:GetFrame(),"RPEServerEventManageActionsAuraRemoveRow");removeRow:AddChild(text(removeRow:GetFrame(),"RPEServerEventManageActionsActiveAuraLabel","Active",42));self.ActionsActiveAuraDropdown=UI.CreateDropdown(removeRow:GetFrame(),"RPEServerEventManageActionsActiveAuraDropdown",{width=335,height=DROPDOWN_HEIGHT,items={},selectedValue="",onValueChanged=function(v)self.ActionsAuraInstanceKey=tostring(v or "");self:RefreshActionsPage()end});removeRow:AddChild(self.ActionsActiveAuraDropdown);self.ActionsRemoveAuraButton=UI.CreateButton(removeRow:GetFrame(),"RPEServerEventManageActionsRemoveAuraButton","Remove Aura",88,function()local ok,r=Server:RemoveEventManagerAura(self.ActionsAuraUnitEventId,self.ActionsAuraInstanceKey);if ok then self.ActionsAuraInstanceKey="" end;self:SetActionsStatus(ok and "Aura removal queued." or ("Remove Aura failed: "..tostring(r or "unknown")));self:RefreshActionsPage()end);removeRow:AddChild(self.ActionsRemoveAuraButton);root:AddChild(removeRow)
    root:AddChild(text(root:GetFrame(),"RPEServerEventManageActionsSkillHeader","Skill Roll",CONTENT_WIDTH,"warning"));local skillRow=row(root:GetFrame(),"RPEServerEventManageActionsSkillRow");self.ActionsSkillUnitDropdown=UI.CreateDropdown(skillRow:GetFrame(),"RPEServerEventManageActionsSkillUnitDropdown",{width=108,height=DROPDOWN_HEIGHT,items={},selectedValue="",onValueChanged=function(v)self.ActionsSkillUnitEventId=tostring(v or "");self:RefreshActionsPage()end});skillRow:AddChild(self.ActionsSkillUnitDropdown);self.ActionsSkillDropdown=UI.CreateDropdown(skillRow:GetFrame(),"RPEServerEventManageActionsSkillDropdown",{width=148,height=DROPDOWN_HEIGHT,items={},selectedValue="",onValueChanged=function(v)self.ActionsSkillRef=tostring(v or "");self:RefreshActionsPage()end});skillRow:AddChild(self.ActionsSkillDropdown);skillRow:AddChild(text(skillRow:GetFrame(),"RPEServerEventManageActionsSkillSuccessLabel","Success >=",55));self.ActionsSkillSuccessInput=UI.CreateTextInput(skillRow:GetFrame(),"RPEServerEventManageActionsSkillSuccessInput",{width=48,height=CONTROL_HEIGHT,text="",justifyH="CENTER"});self.ActionsSkillSuccessInput:SetScript("OnTextChanged",function()self:RefreshActionsPage()end);skillRow:AddChild(self.ActionsSkillSuccessInput);self.ActionsRequestSkillButton=UI.CreateButton(skillRow:GetFrame(),"RPEServerEventManageActionsRequestSkillButton","Request Roll",92,function()local t=trim(self.ActionsSkillSuccessInput:GetText());local ok,r=Server:RequestEventManagerSkillRoll(self.ActionsSkillUnitEventId,self.ActionsSkillRef,t~="" and t or nil);self:SetActionsStatus(ok and "Skill roll requested." or ("Request Roll failed: "..tostring(r or "unknown")));self:RefreshActionsPage()end);skillRow:AddChild(self.ActionsRequestSkillButton);root:AddChild(skillRow)
    self.ActionsStatusText=text(root:GetFrame(),"RPEServerEventManageActionsStatusText","Ready.",CONTENT_WIDTH);root:AddChild(self.ActionsStatusText);if page and page.HookScript then page:HookScript("OnShow",function()EventManage:RefreshActionsPage()end) end;self:RefreshActionsPage();return root
end

return true
