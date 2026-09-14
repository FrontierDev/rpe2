local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
local Client = Addon.Client
local UI = Addon.UI or {}
local Inline = UI.Inline or {}
local Widget = Addon.Client.UI.EventWidget
local Cues = Client.AutopilotSpeechCues or {}

if type(Widget) ~= "table" or Widget._autopilotSpeechCueExtensionInstalled == true
    or type(Widget.EnsureAutopilotHelperUI) ~= "function"
    or type(Cues.GetActionCues) ~= "function"
then return true end

local WIDTH, HEIGHT = 560, 620
local SPEECH_HEIGHT, ROW_HEIGHT, GAP = 164, 15, 3
local ERROR = {
    ["not-host-autopilot"] = "Talking Head cues are only available to the host during Autopilot.",
    ["pending-plan-unavailable"] = "There is no current pending plan.",
    ["pending-plan-stale"] = "The plan is stale. Replan before editing cues.",
    ["pending-action-unavailable"] = "Select a pending spell or movement action first.",
    ["action-already-resolved"] = "This action is already resolved; its cues can no longer be edited.",
    ["speaker-unavailable"] = "Choose an active NPC who participates in this action.",
    ["speech-empty"] = "Enter dialogue text first.",
    ["speech-too-long"] = "Dialogue must be 500 characters or fewer.",
    ["speech-cue-unavailable"] = "That Talking Head cue is no longer available.",
    ["speech-cue-already-sent"] = "A sent cue cannot be changed.",
    ["speech-cue-order-boundary"] = "That cue is already at the end of the list.",
    ["npc-speech-api-unavailable"] = "The NPC speech service is unavailable.",
    ["speech-emission-failed"] = "The NPC speech service could not queue this line.",
}

local function frame(element)
    return type(element) == "table" and type(element.GetFrame) == "function" and element:GetFrame() or element
end

local function shown(element, value)
    local target = frame(element)
    if not target then return end
    if value and target.Show then target:Show() elseif not value and target.Hide then target:Hide() end
end

local function eventState()
    return type(Client.GetEventState) == "function" and Client:GetEventState() or Client.EventState
end

local function eventUnit(eventState, id)
    id = tonumber(id)
    for index = 1, #((eventState and eventState.units) or {}) do
        local unit = eventState.units[index]
        if tonumber(unit and unit.eventID) == id then return unit end
    end
end

local function reasonText(reason)
    local code = tostring(reason or "")
    return ERROR[code] or code
end

local function textButton(parent, name, text, width, handler)
    local button = UI.TextButton:New({
        name = name, width = width, height = 20, text = text, fontSize = 9, fontFlags = "OUTLINE",
        labelColor = UI.ResolveColor(nil, "tab.inactive"), hoverLabelColor = UI.ResolveColor(nil, "text.primary"),
        pressedLabelColor = UI.ResolveColor(nil, "text.primary"), backgroundColor = UI.ResolveColor(nil, "tab.bar"),
        hoverColor = UI.ResolveColor(nil, "panel.background"), pressedColor = UI.ResolveColor(nil, "window.headerBackground"),
        borderTopColor = UI.ResolveColor(nil, "panel.border"), borderBottomColor = UI.ResolveColor(nil, "panel.border"), borderSize = 1,
    })
    button:SetParent(parent)
    button:Create()
    button:SetScript("OnClick", handler)
    return button
end

local function prettySpeaker(speaker)
    local parts = {}
    local marker = math.floor(tonumber(speaker and speaker.raidMarker) or 0)
    if marker >= 1 and marker <= 8 and type(Inline.RaidMarker) == "function" then
        local icon = Inline:RaidMarker(marker, 12, 12)
        if icon ~= "" then parts[#parts + 1] = icon end
    end
    local id = math.floor(tonumber(speaker and speaker.eventId) or 0)
    parts[#parts + 1] = tostring(speaker and speaker.name or "Unknown") .. (id > 0 and (" (#" .. id .. ")") or "")
    return table.concat(parts, " ")
end

local CueRow = {}
CueRow.__index = CueRow
function CueRow:New(options) return setmetatable({ name = options and options.name or "RPEAutopilotSpeechCueRow" }, self) end
function CueRow:SetParent(parent) self.parent = parent end
function CueRow:GetFrame() return self.frame end
function CueRow:Create()
    if self.frame then return self.frame end
    self.frame = CreateFrame("Button", self.name, self.parent)
    self.frame:EnableMouse(true)
    self.background = self.frame:CreateTexture(nil, "BACKGROUND")
    self.background:SetAllPoints(self.frame)
    self.text = self.frame:CreateFontString(nil, "OVERLAY")
    self.text:SetPoint("LEFT", self.frame, "LEFT", 4, 0)
    self.text:SetPoint("RIGHT", self.frame, "RIGHT", -4, 0)
    self.text:SetJustifyH("LEFT")
    self.text:SetJustifyV("MIDDLE")
    self.text:SetWordWrap(false)
    self.text:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    self.frame:SetScript("OnClick", function()
        if type(self.item) == "table" and self.owner and type(self.owner.SelectAutopilotSpeechCue) == "function" then
            self.owner:SelectAutopilotSpeechCue(self.item.id)
        end
    end)
    return self.frame
end
function CueRow:Reset()
    self.item, self.owner = nil, nil
    if self.text then self.text:SetText("") end
end
function CueRow:SetItem(item, owner)
    self.item, self.owner = item, owner
    if type(item) ~= "table" then return self:Reset() end
    local selected = tostring(owner and owner.autopilotSpeechSelectedCueId or "") == tostring(item.id or "")
    local background = UI.ResolveColor(nil, selected and "tab.active" or "panel.background")
    self.background:SetColorTexture(background.r or 0.08, background.g or 0.09, background.b or 0.12, selected and 0.85 or 0.45)
    local speaker = (owner.autopilotSpeechSpeakersById or {})[tonumber(item.speakerEventId)]
    local dialogue = tostring(item.text or ""):gsub("%s+", " ")
    if #dialogue > 36 then dialogue = dialogue:sub(1, 33) .. "..." end
    local status = item.sent == true and "[Sent] " or (item.dispatchAttempted == true and "[Failed] " or "")
    self.text:SetText(status .. prettySpeaker(speaker or { eventId = item.speakerEventId }) .. ": " .. dialogue)
    local color = UI.ResolveColor(nil, selected and "text.primary" or "text.secondary")
    self.text:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
end

function Widget:SetAutopilotSpeechStatus(text, isError)
    if not self.autopilotSpeechStatusText then return end
    self.autopilotSpeechStatusMessage = tostring(text or "")
    self.autopilotSpeechStatusText:SetText(self.autopilotSpeechStatusMessage)
    local color = UI.ResolveColor(nil, isError and "danger" or "text.muted")
    self.autopilotSpeechStatusText:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
end

function Widget:SetAutopilotSpeechDraft(text)
    if not self.autopilotSpeechTextArea then return end
    self._syncingAutopilotSpeechText = true
    self.autopilotSpeechTextArea:SetText(tostring(text or ""))
    self._syncingAutopilotSpeechText = false
    self.autopilotSpeechDraftText = tostring(text or "")
end

function Widget:StoreAutopilotSpeechDraft()
    if self._syncingAutopilotSpeechText or not self.autopilotSpeechTextArea then return end
    self.autopilotSpeechDraftText = tostring(self.autopilotSpeechTextArea:GetText() or "")
end

function Widget:SetAutopilotCueAuthoringMode(mode)
    self.autopilotCueAuthoringMode = mode == "speech" and "speech" or "emote"
    self:RefreshAutopilotSpeechCueUI()
    self:LayoutAutopilotHelperDashboard()
    return true
end

function Widget:SelectAutopilotSpeechCue(cueId)
    self:StoreAutopilotSpeechDraft()
    cueId = tostring(cueId or "")
    local found = nil
    for _, cue in ipairs(self.autopilotSpeechCueRows or {}) do
        if tostring(cue.id or "") == cueId then found = cue; break end
    end
    if not found then return false end
    self.autopilotSpeechSelectedCueId = cueId
    self.autopilotSpeechSelectedSpeakerId = tonumber(found.speakerEventId)
    self.autopilotSpeechSpeakerConfirmed = true
    self:SetAutopilotSpeechDraft(found.text)
    self:RefreshAutopilotSpeechCueUI()
    return true
end

function Widget:AddAutopilotSpeechCue()
    self:StoreAutopilotSpeechDraft()
    local actionId = tostring(self.autopilotSpeechActionId or "")
    local speakerId = tonumber(self.autopilotSpeechSelectedSpeakerId)
    local ok, cue, reason = Cues.AddCue(actionId, speakerId, self.autopilotSpeechDraftText, eventState())
    if not ok then self:SetAutopilotSpeechStatus(reasonText(reason), true); return false, reason end
    self.autopilotSpeechSelectedCueId = nil
    self:SetAutopilotSpeechDraft("")
    self:SetAutopilotSpeechStatus("Talking Head cue added.", false)
    self:RefreshAutopilotSpeechCueUI()
    return true, cue
end

function Widget:UpdateAutopilotSpeechCue()
    self:StoreAutopilotSpeechDraft()
    local ok, cue, reason = Cues.EditCue(
        self.autopilotSpeechActionId, self.autopilotSpeechSelectedCueId, self.autopilotSpeechSelectedSpeakerId,
        self.autopilotSpeechDraftText, eventState()
    )
    if not ok then self:SetAutopilotSpeechStatus(reasonText(reason), true); return false, reason end
    self:SetAutopilotSpeechStatus("Talking Head cue updated.", false)
    self:RefreshAutopilotSpeechCueUI()
    return true, cue
end

function Widget:RemoveAutopilotSpeechCue()
    local ok, reason = Cues.RemoveCue(self.autopilotSpeechActionId, self.autopilotSpeechSelectedCueId, eventState())
    if not ok then self:SetAutopilotSpeechStatus(reasonText(reason), true); return false, reason end
    self.autopilotSpeechSelectedCueId = nil
    self:SetAutopilotSpeechDraft("")
    self:SetAutopilotSpeechStatus("Talking Head cue removed.", false)
    self:RefreshAutopilotSpeechCueUI()
    return true
end

function Widget:MoveAutopilotSpeechCue(direction)
    local ok, reason = Cues.MoveCue(self.autopilotSpeechActionId, self.autopilotSpeechSelectedCueId, direction, eventState())
    if not ok then self:SetAutopilotSpeechStatus(reasonText(reason), true); return false, reason end
    self:RefreshAutopilotSpeechCueUI()
    return true
end

function Widget:EnsureAutopilotSpeechCueUI()
    if self.autopilotSpeechFrame then return true end
    if not self.autopilotDashboardFrame or not self.autopilotToolbarFrame then return false end
    self.autopilotCueAuthoringMode = self.autopilotCueAuthoringMode or "emote"
    self.autopilotSpeechDraftText = tostring(self.autopilotSpeechDraftText or "")

    self.autopilotSpeechFrame = UI.CreatePanel(self.autopilotDashboardFrame, "RPEClientEventWidgetDMAutopilotSpeechPanel", {
        height = SPEECH_HEIGHT, contentInset = 5, showBorder = true, panelBorderSize = 1,
        panelBorderColor = UI.ResolveColor(nil, "panel.border"), panelBackgroundColor = UI.ResolveColor(nil, "panel.background"),
    })
    local content = self.autopilotSpeechFrame:GetContentFrame()
    self.autopilotSpeechContextText = UI.CreateText(content, "RPEClientEventWidgetDMAutopilotSpeechContext", "Talking Head - Select an action", {
        height = 16, fontSize = 10, fontFlags = "OUTLINE", justifyH = "LEFT", justifyV = "MIDDLE", wordWrap = false,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    frame(self.autopilotSpeechContextText):SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)

    self.autopilotSpeechEmoteTabButton = textButton(content, "RPEClientEventWidgetDMAutopilotSpeechEmoteTab", "Emotes", 58, function()
        self:SetAutopilotCueAuthoringMode("emote")
    end)
    frame(self.autopilotSpeechEmoteTabButton):SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)
    frame(self.autopilotSpeechEmoteTabButton):SetHeight(16)
    frame(self.autopilotSpeechContextText):SetPoint("TOPRIGHT", frame(self.autopilotSpeechEmoteTabButton), "TOPLEFT", -GAP, 0)

    self.autopilotSpeechSpeakerRow = CreateFrame("Frame", "RPEClientEventWidgetDMAutopilotSpeechSpeakerRow", content)
    self.autopilotSpeechSpeakerRow:SetHeight(20)
    self.autopilotSpeechSpeakerRow:SetPoint("TOPLEFT", frame(self.autopilotSpeechContextText), "BOTTOMLEFT", 0, -GAP)
    self.autopilotSpeechSpeakerRow:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -19)
    self.autopilotSpeechSpeakerSummary = UI.CreateText(self.autopilotSpeechSpeakerRow, "RPEClientEventWidgetDMAutopilotSpeechSpeaker", "", {
        height = 20, fontSize = 9, fontFlags = "OUTLINE", justifyH = "LEFT", justifyV = "MIDDLE", wordWrap = false,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    frame(self.autopilotSpeechSpeakerSummary):SetAllPoints(self.autopilotSpeechSpeakerRow)
    self.autopilotSpeechSpeakerDropdown = UI.Dropdown:New({
        name = "RPEClientEventWidgetDMAutopilotSpeechSpeakerDropdown", width = 360, height = 20,
        placeholder = "Choose a speaker...", popupWidth = 280, popupMinWidth = 180, fontSize = 9,
        onValueChanged = function(value)
            self.autopilotSpeechSelectedSpeakerId = tonumber(value)
            self.autopilotSpeechSpeakerConfirmed = self.autopilotSpeechSelectedSpeakerId ~= nil
            self:RefreshAutopilotSpeechCueControls()
        end,
    })
    self.autopilotSpeechSpeakerDropdown:SetParent(self.autopilotSpeechSpeakerRow)
    self.autopilotSpeechSpeakerDropdown:Create()
    local dropdownFrame = frame(self.autopilotSpeechSpeakerDropdown)
    dropdownFrame:SetPoint("LEFT", self.autopilotSpeechSpeakerRow, "LEFT", 0, 0)
    dropdownFrame:SetPoint("RIGHT", self.autopilotSpeechSpeakerRow, "RIGHT", 0, 0)
    dropdownFrame:SetHeight(20)

    self.autopilotSpeechTextArea = UI.ClipboardTextArea:New({
        name = "RPEClientEventWidgetDMAutopilotSpeechText", height = 42, readOnly = false, autoResize = false,
        fontSize = 9, fontFlags = "OUTLINE", text = self.autopilotSpeechDraftText,
        textColor = UI.ResolveColor(nil, "text.primary"), backgroundColor = UI.ResolveColor(nil, "panel.background"),
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.autopilotSpeechTextArea:SetParent(content)
    self.autopilotSpeechTextArea:Create()
    frame(self.autopilotSpeechTextArea):SetPoint("TOPLEFT", self.autopilotSpeechSpeakerRow, "BOTTOMLEFT", 0, -GAP)
    frame(self.autopilotSpeechTextArea):SetPoint("TOPRIGHT", self.autopilotSpeechSpeakerRow, "BOTTOMRIGHT", 0, -GAP)
    frame(self.autopilotSpeechTextArea):SetHeight(42)
    self.autopilotSpeechTextArea:SetScript("OnTextChanged", function()
        self:StoreAutopilotSpeechDraft()
        self:RefreshAutopilotSpeechCueControls()
    end)

    self.autopilotSpeechCueScroll = UI.ScrollLayout:New({
        name = "RPEClientEventWidgetDMAutopilotSpeechCueList", rowHeight = ROW_HEIGHT, rowSpacing = 0,
        visibleRows = 2, rowElementClass = CueRow, rowRenderer = function(row, item) row:SetItem(item, self) end,
    })
    self.autopilotSpeechCueScroll:SetParent(content)
    self.autopilotSpeechCueScroll:Create()
    frame(self.autopilotSpeechCueScroll):SetPoint("TOPLEFT", frame(self.autopilotSpeechTextArea), "BOTTOMLEFT", 0, -GAP)
    frame(self.autopilotSpeechCueScroll):SetPoint("TOPRIGHT", frame(self.autopilotSpeechTextArea), "BOTTOMRIGHT", 0, -GAP)
    frame(self.autopilotSpeechCueScroll):SetHeight((ROW_HEIGHT * 2) + 1)

    self.autopilotSpeechButtons = CreateFrame("Frame", "RPEClientEventWidgetDMAutopilotSpeechButtons", content)
    self.autopilotSpeechButtons:SetHeight(20)
    self.autopilotSpeechAddButton = textButton(self.autopilotSpeechButtons, "RPEClientEventWidgetDMAutopilotSpeechAdd", "Add Speech", 76, function() self:AddAutopilotSpeechCue() end)
    self.autopilotSpeechUpdateButton = textButton(self.autopilotSpeechButtons, "RPEClientEventWidgetDMAutopilotSpeechUpdate", "Update", 58, function() self:UpdateAutopilotSpeechCue() end)
    self.autopilotSpeechRemoveButton = textButton(self.autopilotSpeechButtons, "RPEClientEventWidgetDMAutopilotSpeechRemove", "Remove", 56, function() self:RemoveAutopilotSpeechCue() end)
    self.autopilotSpeechUpButton = textButton(self.autopilotSpeechButtons, "RPEClientEventWidgetDMAutopilotSpeechUp", "Up", 34, function() self:MoveAutopilotSpeechCue(-1) end)
    self.autopilotSpeechDownButton = textButton(self.autopilotSpeechButtons, "RPEClientEventWidgetDMAutopilotSpeechDown", "Down", 42, function() self:MoveAutopilotSpeechCue(1) end)
    local buttons = { self.autopilotSpeechAddButton, self.autopilotSpeechUpdateButton, self.autopilotSpeechRemoveButton, self.autopilotSpeechUpButton, self.autopilotSpeechDownButton }
    for index, button in ipairs(buttons) do
        local buttonFrame = frame(button)
        if index == 1 then buttonFrame:SetPoint("LEFT", self.autopilotSpeechButtons, "LEFT", 0, 0)
        else buttonFrame:SetPoint("LEFT", frame(buttons[index - 1]), "RIGHT", GAP, 0) end
    end
    self.autopilotSpeechStatusText = UI.CreateText(self.autopilotSpeechButtons, "RPEClientEventWidgetDMAutopilotSpeechStatus", "", {
        height = 12, fontSize = 8, fontFlags = "OUTLINE", justifyH = "RIGHT", justifyV = "MIDDLE", wordWrap = false,
        textColor = UI.ResolveColor(nil, "text.muted"),
    })
    frame(self.autopilotSpeechStatusText):SetPoint("LEFT", frame(self.autopilotSpeechDownButton), "RIGHT", GAP, 0)
    frame(self.autopilotSpeechStatusText):SetPoint("RIGHT", self.autopilotSpeechButtons, "RIGHT", 0, 0)
    frame(self.autopilotSpeechStatusText):SetPoint("CENTER", self.autopilotSpeechButtons, "CENTER", 0, 0)
    self.autopilotSpeechButtons:SetPoint("TOPLEFT", frame(self.autopilotSpeechCueScroll), "BOTTOMLEFT", 0, -GAP)
    self.autopilotSpeechButtons:SetPoint("TOPRIGHT", frame(self.autopilotSpeechCueScroll), "BOTTOMRIGHT", 0, -GAP)
    return true
end

function Widget:RefreshAutopilotSpeechCueControls()
    if not self.autopilotSpeechFrame then return end
    self:StoreAutopilotSpeechDraft()
    local cues = self.autopilotSpeechCueRows or {}
    local selected = nil
    for _, cue in ipairs(cues) do if tostring(cue.id or "") == tostring(self.autopilotSpeechSelectedCueId or "") then selected = cue; break end end
    local hasAction = tostring(self.autopilotSpeechActionId or "") ~= ""
    local canEdit = hasAction and self.autopilotSpeechActionEditable == true
    local hasText = tostring(self.autopilotSpeechDraftText or ""):match("%S") ~= nil
    local hasSpeaker = tonumber(self.autopilotSpeechSelectedSpeakerId) ~= nil
        and (#(self.autopilotSpeechSpeakers or {}) == 1 or self.autopilotSpeechSpeakerConfirmed == true)
    shown(self.autopilotSpeechAddButton, true)
    shown(self.autopilotSpeechUpdateButton, selected ~= nil)
    self.autopilotSpeechAddButton:SetEnabled(canEdit and hasSpeaker and hasText)
    self.autopilotSpeechUpdateButton:SetEnabled(canEdit and hasSpeaker and hasText and selected ~= nil and selected.sent ~= true and selected.dispatchAttempted ~= true)
    self.autopilotSpeechRemoveButton:SetEnabled(canEdit and selected ~= nil and selected.sent ~= true and selected.dispatchAttempted ~= true)
    self.autopilotSpeechUpButton:SetEnabled(canEdit and selected ~= nil and selected.order > 1 and selected.sent ~= true and selected.dispatchAttempted ~= true)
    self.autopilotSpeechDownButton:SetEnabled(canEdit and selected ~= nil and selected.order < #cues and selected.sent ~= true and selected.dispatchAttempted ~= true)
end

function Widget:RefreshAutopilotSpeechCueUI()
    if not self:EnsureAutopilotSpeechCueUI() then return false end
    self:StoreAutopilotSpeechDraft()
    local state = eventState()
    self.autopilotSpeechEventState = state
    local active = self.combatLogHistoryMode == "dm-helper" and type(state) == "table" and state.active == true
        and tostring(state.turnMode or "manual") == "autopilot" and type(Client.IsLocalEventHost) == "function"
        and Client:IsLocalEventHost(state) == true and self.autopilotDetailsExpanded ~= true
    local entry = type(self.GetSelectedAutopilotHelperEntry) == "function" and self:GetSelectedAutopilotHelperEntry() or nil
    local actionId = type(entry) == "table" and (entry.actionType == "spell" or entry.actionType == "movement")
        and tostring(entry.actionId or "") or ""
    local cues, plan, cueReason, action = {}, nil, nil, nil
    local speakers = {}
    if actionId ~= "" then
        cues, plan, cueReason, action = Cues.GetActionCues(actionId, state)
        speakers = Cues.GetValidSpeakers(actionId, state)
    end
    local planKey = tostring(plan and plan.planId or "")
    local stateKey = table.concat({ tostring(state and state.id or ""), tostring(state and state.turnNumber or ""), planKey, actionId }, "|")
    if stateKey ~= tostring(self.autopilotSpeechDraftKey or "") then
        self.autopilotSpeechDraftKey = stateKey
        self.autopilotSpeechDraftText = ""
        self.autopilotSpeechSelectedCueId = nil
        self.autopilotSpeechSelectedSpeakerId = #speakers == 1 and speakers[1].eventId or nil
        self.autopilotSpeechSpeakerConfirmed = #speakers == 1
        self.autopilotSpeechStatusMessage = ""
        self:SetAutopilotSpeechDraft("")
    elseif #speakers == 1 then
        self.autopilotSpeechSelectedSpeakerId = speakers[1].eventId
        self.autopilotSpeechSpeakerConfirmed = true
    else
        local selectedSpeakerValid = false
        for _, speaker in ipairs(speakers) do
            if tonumber(speaker.eventId) == tonumber(self.autopilotSpeechSelectedSpeakerId) then selectedSpeakerValid = true; break end
        end
        if not selectedSpeakerValid then
            self.autopilotSpeechSelectedSpeakerId = nil
            self.autopilotSpeechSpeakerConfirmed = false
        end
    end
    self.autopilotSpeechActionId = actionId
    self.autopilotSpeechActionEditable = action ~= nil and (action.status == "pending" or action.status == "blocked")
    self.autopilotSpeechCueRows = cues or {}
    self.autopilotSpeechSpeakers = speakers or {}
    self.autopilotSpeechSpeakersById = {}
    local speakerItems = {}
    local cueError = nil
    for _, speaker in ipairs(speakers or {}) do
        self.autopilotSpeechSpeakersById[tonumber(speaker.eventId)] = speaker
        speakerItems[#speakerItems + 1] = { label = prettySpeaker(speaker), value = tonumber(speaker.eventId) }
    end
    for _, cue in ipairs(cues or {}) do
        cueError = cueError or cue.lastError
        local id = tonumber(cue.speakerEventId)
        if id and not self.autopilotSpeechSpeakersById[id] then
            local unit = eventUnit(state, id)
            if unit then
                self.autopilotSpeechSpeakersById[id] = {
                    eventId = id, name = tostring(unit.name or ("Unit " .. id)), raidMarker = tonumber(unit.raidMarker) or 0,
                }
            end
        end
    end

    local title = "Talking Head - Select a pending spell or movement action"
    if type(entry) == "table" and actionId ~= "" then
        local summary = tostring(entry.displayText or entry.summary or entry.kind or "Pending action")
        if #summary > 62 then summary = summary:sub(1, 59) .. "..." end
        title = "Talking Head - " .. summary
    end
    self.autopilotSpeechContextText:SetText(title)
    if #speakers > 1 then
        shown(self.autopilotSpeechSpeakerDropdown, true)
        shown(self.autopilotSpeechSpeakerSummary, false)
        self.autopilotSpeechSpeakerDropdown:SetItems(speakerItems)
        if self.autopilotSpeechSelectedSpeakerId then
            self.autopilotSpeechSpeakerDropdown:SetSelectedValue(self.autopilotSpeechSelectedSpeakerId, true)
        else
            local dropdown = self.autopilotSpeechSpeakerDropdown
            dropdown.selectedIndex, dropdown.selectedValue, dropdown.selectedValues, dropdown.selectedValueOrder = 0, nil, {}, {}
            dropdown:UpdateLabel()
        end
    else
        shown(self.autopilotSpeechSpeakerDropdown, false)
        shown(self.autopilotSpeechSpeakerSummary, true)
        self.autopilotSpeechSpeakerSummary:SetText(#speakers == 1
            and ("Speaker: " .. prettySpeaker(speakers[1]))
            or (actionId ~= "" and "No active NPC speaker is available for this action." or "Select an action above to choose its NPC speaker."))
    end
    self.autopilotSpeechCueScroll:SetItems(self.autopilotSpeechCueRows)
    if cueError then self:SetAutopilotSpeechStatus(reasonText(cueError), true)
    elseif cueReason and actionId ~= "" then self:SetAutopilotSpeechStatus(reasonText(cueReason), true)
    elseif tostring(self.autopilotSpeechStatusMessage or "") == "" then
        self:SetAutopilotSpeechStatus(actionId == "" and "Select an action to queue Talking Head dialogue." or "Add dialogue to queue it before this action.", false)
    end
    self:RefreshAutopilotSpeechCueControls()
    shown(self.autopilotSpeechFrame, active and self.autopilotCueAuthoringMode == "speech")
    return true
end

local baseEnsure = Widget.EnsureAutopilotHelperUI
local baseLayout = Widget.LayoutAutopilotHelperDashboard
local baseRefresh = Widget.RefreshAutopilotHelperDashboard
local baseExpand = Widget.SetAutopilotDetailsExpanded
local baseSelect = Widget.SelectAutopilotHelperDetail
local baseClear = Widget.ClearAutopilotHelperSelection

function Widget:EnsureAutopilotHelperUI(...)
    local result = baseEnsure(self, ...)
    if result then self:EnsureAutopilotSpeechCueUI() end
    return result
end

function Widget:LayoutAutopilotHelperDashboard(...)
    local result = baseLayout(self, ...)
    if self.autopilotSpeechFrame and self.autopilotToolbarFrame then
        local speech = frame(self.autopilotSpeechFrame)
        speech:ClearAllPoints()
        speech:SetPoint("BOTTOMLEFT", self.autopilotToolbarFrame, "TOPLEFT", 0, GAP + 1)
        speech:SetPoint("BOTTOMRIGHT", self.autopilotToolbarFrame, "TOPRIGHT", 0, GAP + 1)
        speech:SetHeight(SPEECH_HEIGHT)
        local active = self.combatLogHistoryMode == "dm-helper" and self.autopilotDetailsExpanded ~= true
        shown(self.autopilotSpeechFrame, active and self.autopilotCueAuthoringMode == "speech")
        shown(self.autopilotEmoteFrame, active and self.autopilotCueAuthoringMode ~= "speech")
        if self.autopilotDetailToggleButton and self.autopilotDetailsExpanded ~= true then
            local details = frame(self.autopilotDetailToggleButton)
            details:ClearAllPoints()
            details:SetPoint("BOTTOMLEFT", speech, "TOPLEFT", 0, GAP)
            details:SetPoint("BOTTOMRIGHT", speech, "TOPRIGHT", 0, GAP)
        end
    end
    return result
end

function Widget:RefreshAutopilotHelperDashboard(...)
    local result = baseRefresh(self, ...)
    local panel = frame(self.combatLogHistoryPanel)
    if panel and self.combatLogHistoryMode == "dm-helper" then panel:SetSize(WIDTH, HEIGHT) end
    self:RefreshAutopilotSpeechCueUI()
    self:LayoutAutopilotHelperDashboard()
    return result
end

function Widget:SetAutopilotDetailsExpanded(expanded, ...)
    local result = baseExpand(self, expanded, ...)
    self:RefreshAutopilotSpeechCueUI()
    self:LayoutAutopilotHelperDashboard()
    return result
end

function Widget:SelectAutopilotHelperDetail(entry, ...)
    local result = baseSelect(self, entry, ...)
    self:RefreshAutopilotSpeechCueUI()
    return result
end

function Widget:ClearAutopilotHelperSelection(...)
    local result = baseClear(self, ...)
    self.autopilotSpeechActionId, self.autopilotSpeechSelectedCueId = nil, nil
    self.autopilotSpeechDraftKey, self.autopilotSpeechDraftText = nil, ""
    self.autopilotSpeechSelectedSpeakerId, self.autopilotSpeechSpeakerConfirmed = nil, false
    if self.autopilotSpeechTextArea then self:SetAutopilotSpeechDraft("") end
    self:RefreshAutopilotSpeechCueUI()
    self:LayoutAutopilotHelperDashboard()
    return result
end

Widget._autopilotSpeechCueExtensionInstalled = true
return true
