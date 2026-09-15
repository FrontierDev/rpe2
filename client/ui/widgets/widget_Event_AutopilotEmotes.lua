local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
local Client = Addon.Client
local UI = Addon.UI or {}
local Inline = UI.Inline or {}
local Widget = Addon.Client.UI.EventWidget
local Cues = Client.AutopilotEmoteCues or {}

if type(Widget) ~= "table" or Widget._autopilotEmoteCueExtensionInstalled == true
    or type(Widget.EnsureAutopilotHelperUI) ~= "function" or type(Cues.GetParticipatingUnits) ~= "function"
then return true end

local EMOTE_HEIGHT = 164
local UNIT_HEIGHT, TEXT_HEIGHT, BUTTON_HEIGHT, GAP = 54, 48, 20, 4
local ERROR = {
    ["not-host-autopilot"] = "Emotes are only available to the host during an Autopilot event.",
    ["pending-plan-unavailable"] = "There is no current pending plan.",
    ["pending-plan-stale"] = "The pending plan is stale. Replan before assigning an emote.",
    ["no-units-selected"] = "Select at least one NPC unit.",
    ["emote-empty"] = "Enter emote text first.",
    ["message-too-long"] = "The composed group-chat message is too long. Shorten the emote text.",
    ["not-in-group"] = "The emote could not be sent because you are not in a party or raid.",
    ["chat-api-unavailable"] = "The group-chat API is unavailable.",
    ["outcome-unavailable"] = "Select an outcome from this turn before sending.",
}

local function frame(element)
    return type(element) == "table" and type(element.GetFrame) == "function" and element:GetFrame() or element
end
local function shown(element, value)
    local target = frame(element); if not target then return end
    if value and target.Show then target:Show() elseif not value and target.Hide then target:Hide() end
end
local function eventState()
    return type(Client.GetEventState) == "function" and Client:GetEventState() or Client.EventState
end
local function reasonText(reason) local code = tostring(reason or ""); return ERROR[code] or code end
local function textButton(parent, name, text, width, handler)
    local button = UI.TextButton:New({
        name=name, width=width, height=BUTTON_HEIGHT, text=text, fontSize=9, fontFlags="OUTLINE",
        labelColor=UI.ResolveColor(nil,"tab.inactive"), hoverLabelColor=UI.ResolveColor(nil,"text.primary"),
        pressedLabelColor=UI.ResolveColor(nil,"text.primary"), backgroundColor=UI.ResolveColor(nil,"tab.bar"),
        hoverColor=UI.ResolveColor(nil,"panel.background"), pressedColor=UI.ResolveColor(nil,"window.headerBackground"),
        borderTopColor=UI.ResolveColor(nil,"panel.border"), borderBottomColor=UI.ResolveColor(nil,"panel.border"), borderSize=1,
    })
    button:SetParent(parent); button:Create(); button:SetScript("OnClick", handler); return button
end
local function selectedIds(self)
    local ids, selected = {}, self.selectedAutopilotEmoteUnitIds or {}
    for _, item in ipairs(self.autopilotEmoteUnitRows or {}) do
        local id = math.floor(tonumber(item and item.eventId) or 0)
        if id > 0 and selected[id] then ids[#ids + 1] = id end
    end
    return ids
end
local function selectedCount(self)
    local count = 0; for _, value in pairs(self.selectedAutopilotEmoteUnitIds or {}) do if value then count = count + 1 end end
    return count
end

local UnitRow = {}; UnitRow.__index = UnitRow
function UnitRow:New(options) return setmetatable({name=options and options.name or "RPEAutopilotEmoteUnitRow"}, self) end
function UnitRow:SetParent(parent) self.parent = parent end
function UnitRow:GetFrame() return self.frame end
function UnitRow:Create()
    if self.frame then return self.frame end
    self.frame = CreateFrame("Frame", self.name, self.parent)
    self.checkbox = UI.Checkbox:New({
        name=self.name.."Checkbox", height=17, boxSize=11, labelOffset=4, contentInsetLeft=1, contentInsetRight=2,
        fontSize=9, fontFlags="OUTLINE", text="",
        onValueChanged=function(checked)
            if self.item and self.owner and type(self.owner.SetAutopilotEmoteUnitSelected) == "function" then
                self.owner:SetAutopilotEmoteUnitSelected(self.item.eventId, checked == true)
            end
        end,
    })
    self.checkbox:SetParent(self.frame); self.checkbox:Create()
    frame(self.checkbox):SetAllPoints(self.frame)
    return self.frame
end
function UnitRow:Reset()
    self.item, self.owner = nil, nil
    if self.checkbox then self.checkbox:SetText(""); self.checkbox:SetChecked(false, true) end
end
function UnitRow:SetItem(item, owner)
    self.item, self.owner = item, owner
    if type(item) ~= "table" then return self:Reset() end
    local parts, marker = {}, math.floor(tonumber(item.raidMarker) or 0)
    if marker >= 1 and marker <= 8 and type(Inline.RaidMarker) == "function" then
        local icon = Inline:RaidMarker(marker, 12, 12); if icon ~= "" then parts[#parts + 1] = icon end
    end
    parts[#parts + 1] = ("%d %s"):format(math.floor(tonumber(item.eventId) or 0), tostring(item.name or "Unknown"))
    if item.hasCue then parts[#parts + 1] = "[Emote]" end
    self.checkbox:SetText(table.concat(parts, " "))
    self.checkbox:SetChecked((owner.selectedAutopilotEmoteUnitIds or {})[math.floor(tonumber(item.eventId) or 0)] == true, true)
end

function Widget:SetAutopilotEmoteStatus(text, isError)
    if not self.autopilotEmoteStatusText then return end
    self.autopilotEmoteStatusText:SetText(tostring(text or ""))
    local color = UI.ResolveColor(nil, isError and "danger" or "text.muted")
    self.autopilotEmoteStatusText:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
end
function Widget:SetAutopilotEmoteText(text)
    if not self.autopilotEmoteTextArea then return end
    self._syncingAutopilotEmoteText = true; self.autopilotEmoteTextArea:SetText(tostring(text or "")); self._syncingAutopilotEmoteText = false
end
function Widget:StoreAutopilotEmoteDraft()
    if self._syncingAutopilotEmoteText or not self.autopilotEmoteTextArea then return end
    local text = tostring(self.autopilotEmoteTextArea:GetText() or "")
    if self.autopilotEmoteMode == "outcome" then
        local key = tostring(self.autopilotEmoteOutcomeEntryId or "")
        if key ~= "" then self.autopilotOutcomeEmoteDrafts[key] = text end
    else self.autopilotUnitEmoteDraft = text end
end
function Widget:SyncAutopilotEmoteCueFromSelection()
    local cue = Cues.GetSharedCue(selectedIds(self), eventState())
    if type(cue) == "table" and cue.sent ~= true then
        self.autopilotEmoteEditingCueId, self.autopilotUnitEmoteDraft = tostring(cue.id or ""), tostring(cue.body or "")
        if self.autopilotEmoteMode ~= "outcome" then self:SetAutopilotEmoteText(self.autopilotUnitEmoteDraft) end
    else self.autopilotEmoteEditingCueId = nil end
    self:RefreshAutopilotEmoteCueUI()
end
function Widget:SetAutopilotEmoteUnitSelected(id, value)
    id = math.floor(tonumber(id) or 0); if id <= 0 then return false end
    self.selectedAutopilotEmoteUnitIds[id] = value == true and true or nil
    self:SyncAutopilotEmoteCueFromSelection(); return true
end
function Widget:AssignAutopilotEmoteCue()
    self:StoreAutopilotEmoteDraft()
    local ok, cue, reason = Cues.AssignCue(selectedIds(self), self.autopilotUnitEmoteDraft, self.autopilotEmoteEditingCueId, eventState())
    if not ok then self:SetAutopilotEmoteStatus(reasonText(reason), true); return false, reason end
    self.autopilotEmoteEditingCueId, self.autopilotUnitEmoteDraft = cue.id, cue.body
    self:SetAutopilotEmoteStatus("Emote cue assigned.", false); return true, cue
end
function Widget:ClearSelectedAutopilotEmoteCues()
    local ok, reason = Cues.ClearCueForUnits(selectedIds(self), eventState())
    if not ok then self:SetAutopilotEmoteStatus(reasonText(reason), true); return false, reason end
    self.autopilotEmoteEditingCueId, self.autopilotUnitEmoteDraft = nil, ""; self:SetAutopilotEmoteText("")
    self:SetAutopilotEmoteStatus("Emote cue cleared for selected units.", false); return true
end
function Widget:SendSelectedAutopilotOutcomeEmote()
    self:StoreAutopilotEmoteDraft()
    local selected = type(self.GetSelectedAutopilotHelperEntry) == "function" and self:GetSelectedAutopilotHelperEntry() or nil
    if type(selected) ~= "table" or selected.kind ~= "outcome" then self:SetAutopilotEmoteStatus(reasonText("outcome-unavailable"), true); return false end
    local key = tostring(selected.entryId or "")
    local ok, messageOrReason = Cues.SendOutcomeEmote(selected, self.autopilotOutcomeEmoteDrafts[key] or "", eventState())
    if not ok then self:SetAutopilotEmoteStatus(reasonText(messageOrReason), true); return false, messageOrReason end
    self.autopilotOutcomeEmoteDrafts[key] = ""; self:SetAutopilotEmoteText(""); self:SetAutopilotEmoteStatus("Outcome emote sent.", false)
    return true, messageOrReason
end

function Widget:EnsureAutopilotEmoteCueUI()
    if self.autopilotEmoteFrame then return true end
    if not self.autopilotCueAuthoringContentFrame then return false end
    self.selectedAutopilotEmoteUnitIds, self.autopilotOutcomeEmoteDrafts = self.selectedAutopilotEmoteUnitIds or {}, self.autopilotOutcomeEmoteDrafts or {}
    self.autopilotUnitEmoteDraft, self.autopilotEmoteMode = tostring(self.autopilotUnitEmoteDraft or ""), tostring(self.autopilotEmoteMode or "units")

    self.autopilotEmoteFrame = UI.CreatePanel(self.autopilotCueAuthoringContentFrame, "RPEClientEventWidgetDMAutopilotEmotePanel", {
        height=EMOTE_HEIGHT, contentInset=5, showBorder=true, panelBorderSize=1,
        panelBorderColor=UI.ResolveColor(nil,"panel.border"), panelBackgroundColor=UI.ResolveColor(nil,"panel.background"),
    })
    local content = self.autopilotEmoteFrame:GetContentFrame()
    self.autopilotEmoteContextText = UI.CreateText(content, "RPEClientEventWidgetDMAutopilotEmoteContext", "Emote — Selected Units", {
        height=16, fontSize=10, fontFlags="OUTLINE", justifyH="LEFT", justifyV="MIDDLE", wordWrap=false, textColor=UI.ResolveColor(nil,"text.secondary"),
    })
    frame(self.autopilotEmoteContextText):SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    frame(self.autopilotEmoteContextText):SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)

    self.autopilotEmoteUnitScroll = UI.ScrollLayout:New({
        name="RPEClientEventWidgetDMAutopilotEmoteUnits", rowHeight=17, rowSpacing=1, visibleRows=3, rowElementClass=UnitRow,
        rowRenderer=function(row,item) row:SetItem(item,self) end,
    })
    self.autopilotEmoteUnitScroll:SetParent(content); self.autopilotEmoteUnitScroll:Create()
    frame(self.autopilotEmoteUnitScroll):SetHeight(UNIT_HEIGHT)

    self.autopilotEmoteTextArea = UI.ClipboardTextArea:New({
        name="RPEClientEventWidgetDMAutopilotEmoteText", height=TEXT_HEIGHT, readOnly=false, autoResize=false,
        fontSize=9, fontFlags="OUTLINE", text=self.autopilotUnitEmoteDraft, textColor=UI.ResolveColor(nil,"text.primary"),
        backgroundColor=UI.ResolveColor(nil,"panel.background"), borderColor=UI.ResolveColor(nil,"panel.border"),
    })
    self.autopilotEmoteTextArea:SetParent(content); self.autopilotEmoteTextArea:Create()
    self.autopilotEmoteTextArea:SetScript("OnTextChanged", function() self:StoreAutopilotEmoteDraft(); self:RefreshAutopilotEmoteCueControls() end)

    self.autopilotEmoteButtons = CreateFrame("Frame", "RPEClientEventWidgetDMAutopilotEmoteButtons", content); self.autopilotEmoteButtons:SetHeight(BUTTON_HEIGHT)
    self.autopilotAssignEmoteButton = textButton(self.autopilotEmoteButtons,"RPEClientEventWidgetDMAutopilotAssignEmote","Assign Cue",80,function() self:AssignAutopilotEmoteCue() end)
    self.autopilotClearEmoteButton = textButton(self.autopilotEmoteButtons,"RPEClientEventWidgetDMAutopilotClearEmote","Clear",58,function() self:ClearSelectedAutopilotEmoteCues() end)
    self.autopilotSendOutcomeEmoteButton = textButton(self.autopilotEmoteButtons,"RPEClientEventWidgetDMAutopilotSendOutcomeEmote","Send",58,function() self:SendSelectedAutopilotOutcomeEmote() end)
    frame(self.autopilotAssignEmoteButton):SetPoint("LEFT", self.autopilotEmoteButtons, "LEFT", 0, 0)
    frame(self.autopilotClearEmoteButton):SetPoint("LEFT", frame(self.autopilotAssignEmoteButton), "RIGHT", GAP, 0)
    frame(self.autopilotSendOutcomeEmoteButton):SetPoint("LEFT", self.autopilotEmoteButtons, "LEFT", 0, 0); shown(self.autopilotSendOutcomeEmoteButton, false)
    self.autopilotEmoteStatusText = UI.CreateText(content,"RPEClientEventWidgetDMAutopilotEmoteStatus","",{
        height=12,fontSize=8,fontFlags="OUTLINE",justifyH="RIGHT",justifyV="MIDDLE",wordWrap=false,textColor=UI.ResolveColor(nil,"text.muted"),
    })
    frame(self.autopilotEmoteStatusText):SetPoint("LEFT", frame(self.autopilotClearEmoteButton), "RIGHT", GAP, 0)
    frame(self.autopilotEmoteStatusText):SetPoint("RIGHT", self.autopilotEmoteButtons, "RIGHT", 0, 0)
    frame(self.autopilotEmoteStatusText):SetPoint("CENTER", self.autopilotEmoteButtons, "CENTER", 0, 0)
    return true
end

function Widget:RefreshAutopilotEmoteCueControls()
    if not self.autopilotEmoteFrame then return end
    local hasText = tostring(self.autopilotEmoteTextArea:GetText() or ""):match("%S") ~= nil
    local outcome = self.autopilotEmoteMode == "outcome"; local count = selectedCount(self)
    shown(self.autopilotAssignEmoteButton, not outcome); shown(self.autopilotClearEmoteButton, not outcome); shown(self.autopilotSendOutcomeEmoteButton, outcome)
    if outcome then self.autopilotSendOutcomeEmoteButton:SetEnabled(hasText and tostring(self.autopilotEmoteOutcomeEntryId or "") ~= "")
    else self.autopilotAssignEmoteButton:SetEnabled(count > 0 and hasText); self.autopilotClearEmoteButton:SetEnabled(count > 0) end
end

function Widget:RefreshAutopilotEmoteCueUI()
    if not self:EnsureAutopilotEmoteCueUI() then return false end
    local state = eventState()
    local units, plan = Cues.GetParticipatingUnits(state)
    local eventKey, turn, planKey = tostring(state.id or ""), math.max(0,math.floor(tonumber(state.turnNumber) or 0)), tostring(plan and plan.planId or "")
    local turnChanged = tostring(self.autopilotEmoteEventId or "") ~= eventKey or tonumber(self.autopilotEmoteTurnNumber) ~= turn
    local planChanged = tostring(self.autopilotEmotePlanId or "") ~= planKey
    if turnChanged then
        self.selectedAutopilotEmoteUnitIds, self.autopilotOutcomeEmoteDrafts, self.autopilotUnitEmoteDraft = {}, {}, ""
        self.autopilotEmoteEditingCueId, self.autopilotEmoteOutcomeEntryId, self.autopilotEmoteMode = nil, nil, "units"; self:SetAutopilotEmoteText("")
    elseif planChanged then
        self.selectedAutopilotEmoteUnitIds, self.autopilotUnitEmoteDraft, self.autopilotEmoteEditingCueId = {}, "", nil
        if self.autopilotEmoteMode ~= "outcome" then self:SetAutopilotEmoteText("") end
    end
    self.autopilotEmoteEventId, self.autopilotEmoteTurnNumber, self.autopilotEmotePlanId = eventKey, turn, planKey
    self.autopilotEmoteUnitRows = units or {}
    local valid = {}; for _, item in ipairs(units or {}) do valid[math.floor(tonumber(item.eventId) or 0)] = true end
    for id in pairs(self.selectedAutopilotEmoteUnitIds) do if not valid[math.floor(tonumber(id) or 0)] then self.selectedAutopilotEmoteUnitIds[id] = nil end end

    local selected = type(self.GetSelectedAutopilotHelperEntry) == "function" and self:GetSelectedAutopilotHelperEntry() or nil
    local nextMode = type(selected) == "table" and selected.kind == "outcome" and "outcome" or "units"
    local nextOutcome = nextMode == "outcome" and tostring(selected.entryId or "") or ""
    local changed = nextMode ~= self.autopilotEmoteMode or nextOutcome ~= tostring(self.autopilotEmoteOutcomeEntryId or "")
    self:StoreAutopilotEmoteDraft(); self.autopilotEmoteMode, self.autopilotEmoteOutcomeEntryId = nextMode, nextOutcome ~= "" and nextOutcome or nil

    local context, unitScroll, area = frame(self.autopilotEmoteContextText), frame(self.autopilotEmoteUnitScroll), frame(self.autopilotEmoteTextArea)
    if nextMode == "outcome" then
        self.autopilotEmoteContextText:SetText("Emote — Selected Outcome"); shown(self.autopilotEmoteUnitScroll, false)
        area:ClearAllPoints(); area:SetPoint("TOPLEFT",context,"BOTTOMLEFT",0,-2); area:SetPoint("TOPRIGHT",context,"BOTTOMRIGHT",0,-2); area:SetHeight(TEXT_HEIGHT + UNIT_HEIGHT)
        if changed then self:SetAutopilotEmoteText(self.autopilotOutcomeEmoteDrafts[nextOutcome] or "") end
    else
        self.autopilotEmoteContextText:SetText(("Emote — Selected Units (%d)"):format(selectedCount(self))); shown(self.autopilotEmoteUnitScroll, true)
        self.autopilotEmoteUnitScroll:SetItems(units or {}); unitScroll:ClearAllPoints(); unitScroll:SetPoint("TOPLEFT",context,"BOTTOMLEFT",0,-2); unitScroll:SetPoint("TOPRIGHT",context,"BOTTOMRIGHT",0,-2); unitScroll:SetHeight(UNIT_HEIGHT)
        area:ClearAllPoints(); area:SetPoint("TOPLEFT",unitScroll,"BOTTOMLEFT",0,-2); area:SetPoint("TOPRIGHT",unitScroll,"BOTTOMRIGHT",0,-2); area:SetHeight(TEXT_HEIGHT)
        if changed then self:SetAutopilotEmoteText(self.autopilotUnitEmoteDraft) end
    end
    self.autopilotEmoteButtons:ClearAllPoints(); self.autopilotEmoteButtons:SetPoint("TOPLEFT",area,"BOTTOMLEFT",0,-GAP); self.autopilotEmoteButtons:SetPoint("TOPRIGHT",area,"BOTTOMRIGHT",0,-GAP)
    if plan and plan.emoteCueLastError then self:SetAutopilotEmoteStatus(reasonText(plan.emoteCueLastError), true) end
    self:RefreshAutopilotEmoteCueControls(); return true
end

function Widget:ResetAutopilotEmoteCueAuthoring()
    self.selectedAutopilotEmoteUnitIds, self.autopilotEmoteEditingCueId, self.autopilotEmoteOutcomeEntryId, self.autopilotEmoteMode = {}, nil, nil, "units"
    self.autopilotUnitEmoteDraft, self.autopilotOutcomeEmoteDrafts = "", {}; if self.autopilotEmoteTextArea then self:SetAutopilotEmoteText("") end
    return true
end

Widget:RegisterAutopilotCueAuthoringMode("emote", {
    label = "Emotes",
    tabWidth = 62,
    ensureMethod = "EnsureAutopilotEmoteCueUI",
    refreshMethod = "RefreshAutopilotEmoteCueUI",
    resetMethod = "ResetAutopilotEmoteCueAuthoring",
    frameField = "autopilotEmoteFrame",
})

Widget._autopilotEmoteCueExtensionInstalled = true
return true
