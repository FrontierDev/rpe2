local _, Addon = ...

Addon.Client = Addon.Client or {}

local Client = Addon.Client
local Common = Addon.Utils and Addon.Utils.Common or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}

local function startTiming(label, thresholdMs, context)
    local timings = Addon.Debug and Addon.Debug.Timings or nil
    if timings and type(timings.Start) == "function" then
        if type(timings.IsEnabled) == "function" and not timings:IsEnabled() then
            return nil
        end
        return timings:Start(label, {
            thresholdMs = thresholdMs,
            context = context,
        })
    end
    return nil
end

local function stopTiming(timer, cardinality)
    if not timer then
        return
    end

    local timings = Addon.Debug and Addon.Debug.Timings or nil
    if timings and type(timings.Stop) == "function" then
        timings:Stop(timer, { cardinality = cardinality })
    end
end

local Achievements = Client.Achievements or {}
Client.Achievements = Achievements

local SUPPORTED_TRIGGERS = {
    manual = true,
    currency_gain = true,
    rpe_kill = true,
    rpe_event_complete = true,
    achievement_earned = true,
    item_gain = true,
    skill_gain = true,
    rpe_boss_kill = true,
    rpe_damage = true,
    rpe_healing = true,
    rpe_event_started = true,
}

local function trimText(value)
    local text = tostring(value or "")
    return text:gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeName(value)
    local name = trimText(value)
    if type(Common.NormalizeName) == "function" then
        return Common.NormalizeName(name)
    end

    return name
end

local function normalizeInteger(value, minimum)
    local numeric = tonumber(value)
    if not numeric or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        return minimum or 0
    end

    return math.max(minimum or 0, math.floor(numeric))
end

local function normalizeTrigger(value)
    local trigger = string.lower(trimText(value))
    return SUPPORTED_TRIGGERS[trigger] and trigger or ""
end

local function composeAchievementRef(datasetId, achievementId)
    local normalizedDatasetId = trimText(datasetId)
    local normalizedAchievementId = trimText(achievementId)
    if normalizedDatasetId == "" or normalizedAchievementId == "" then
        return ""
    end

    return ("%s:%s"):format(normalizedDatasetId, normalizedAchievementId)
end

local function getActivatedDatasetSignature()
    if type(Registry.ListActivatedDatasetIds) ~= "function" then
        return ""
    end

    local ids = Registry:ListActivatedDatasetIds() or {}
    local normalizedIds = {}
    for index = 1, #ids do
        normalizedIds[index] = trimText(ids[index])
    end

    return table.concat(normalizedIds, "\31")
end

local function getAchievementRef(entry)
    return composeAchievementRef(
        entry and entry.datasetId,
        entry and entry.achievementId
    )
end

local function getAchievementState(achievementRef)
    local state = type(Profile.GetAchievementState) == "function"
        and Profile.GetAchievementState(achievementRef)
        or nil
    local normalized = {
        criteria = {},
        completedAt = nil,
    }

    if type(state) ~= "table" then
        return normalized
    end

    for criterionId, progress in pairs(type(state.criteria) == "table" and state.criteria or {}) do
        local normalizedCriterionId = trimText(criterionId)
        if normalizedCriterionId ~= "" then
            normalized.criteria[normalizedCriterionId] = normalizeInteger(progress, 0)
        end
    end

    local completedAt = tonumber(state.completedAt)
    if completedAt ~= nil
        and completedAt == completedAt
        and completedAt ~= math.huge
        and completedAt ~= -math.huge
        and completedAt >= 0 then
        normalized.completedAt = completedAt
    end

    return normalized
end

local function getCriterionGoal(criterion)
    return normalizeInteger(criterion and criterion.goal, 1)
end

local function isAchievementComplete(achievement, state)
    local criteria = achievement and achievement.criteria or nil
    if type(criteria) ~= "table" or #criteria == 0 then
        return false
    end

    local stateCriteria = state and state.criteria or {}
    for index = 1, #criteria do
        local criterion = criteria[index]
        local criterionId = trimText(criterion and criterion.id)
        if criterionId == ""
            or normalizeInteger(stateCriteria[criterionId], 0) < getCriterionGoal(criterion) then
            return false
        end
    end

    return true
end

local function normalizeCurrencyReference(value)
    local reference = trimText(value)
    if reference == "" then
        return ""
    end

    if type(Profile.NormalizeCurrencyKey) == "function" then
        return Profile.NormalizeCurrencyKey(reference)
    end

    return string.lower(reference)
end

local function getLocalPlayerName()
    if type(Common.GetPlayerName) == "function" then
        return normalizeName(Common.GetPlayerName())
    end

    return ""
end

local function isBossEventUnit(unit)
    if type(unit) ~= "table" then
        return false
    end

    local eventUnitClass = Addon.Internal
        and Addon.Internal.Database
        and Addon.Internal.Database.Classes
        and Addon.Internal.Database.Classes.EventUnit
        or nil
    if eventUnitClass and type(eventUnitClass.IsBoss) == "function" then
        return eventUnitClass.IsBoss(unit) == true
    end

    return unit.boss == true
end

local function matchesUnitFilters(filters, event)
    local configuredUnit = trimText(filters.unitRef)
    if configuredUnit ~= "" and configuredUnit ~= trimText(event.unitRef) then
        return false
    end

    if filters.enemyOnly == true and event.isEnemy ~= true then
        return false
    end

    return true
end

local function matchesCriterion(entry, trigger, context)
    local criterion = entry and entry.criterion or {}
    local filters = type(criterion.filters) == "table" and criterion.filters or {}
    local event = type(context) == "table" and context or {}

    if trigger == "manual" and trimText(event.achievementRef) ~= "" then
        if trimText(event.achievementRef) ~= getAchievementRef(entry) then
            return false
        end
    end

    if trigger == "manual" and trimText(event.criterionId) ~= "" then
        if trimText(event.criterionId) ~= trimText(criterion.id) then
            return false
        end
    end

    if trigger == "currency_gain" then
        local configuredCurrency = normalizeCurrencyReference(filters.currencyRef)
        if configuredCurrency ~= ""
            and configuredCurrency ~= normalizeCurrencyReference(event.currencyRef) then
            return false
        end
    elseif trigger == "item_gain" then
        local configuredItem = trimText(filters.itemRef)
        if configuredItem ~= "" and configuredItem ~= trimText(event.itemRef) then
            return false
        end
    elseif trigger == "skill_gain" then
        local configuredSkill = trimText(filters.skillRef)
        if configuredSkill ~= "" and configuredSkill ~= trimText(event.skillRef) then
            return false
        end
    elseif trigger == "rpe_kill"
        or trigger == "rpe_boss_kill"
        or trigger == "rpe_damage"
        or trigger == "rpe_healing"
    then
        if not matchesUnitFilters(filters, event) then
            return false
        end
    elseif trigger == "rpe_event_started" then
        local configuredEvent = trimText(filters.eventId)
        if configuredEvent ~= "" and configuredEvent ~= trimText(event.eventId) then
            return false
        end
    elseif trigger == "achievement_earned" then
        local configuredAchievement = trimText(filters.achievementRef)
        if configuredAchievement ~= ""
            and configuredAchievement ~= trimText(event.achievementRef) then
            return false
        end
    end

    return true
end

local function refreshProfileUI()
    local profileUI = Client.UI and Client.UI.Profile or nil
    local profileWindow = profileUI and profileUI.Window or nil
    local instance = type(profileWindow) == "table" and profileWindow._singleton or nil
    if instance and type(instance.RefreshVisible) == "function" then
        instance:RefreshVisible()
    elseif instance and type(instance.Refresh) == "function" then
        instance:Refresh()
    end
end

local function sendVisibleChatMessage(message, chatType)
    if type(SendChatMessage) ~= "function" or message == "" then
        return false
    end

    local callOk = pcall(SendChatMessage, message, chatType)
    return callOk
end

local function announceAchievement(achievement)
    local achievementName = trimText(achievement and achievement.name)
    if achievementName == "" then
        achievementName = trimText(achievement and achievement.id)
    end
    if achievementName == "" then
        achievementName = "Unnamed Achievement"
    end

    local playerName = getLocalPlayerName()
    if playerName == "" then
        playerName = "A player"
    end

    local message = ("[RPE] %s has earned the achievement [%s]!"):format(playerName, achievementName)
    if type(IsInGuild) == "function" and IsInGuild() == true then
        sendVisibleChatMessage(message, "GUILD")
    end
    if type(IsInRaid) == "function" and IsInRaid() == true then
        sendVisibleChatMessage(message, "RAID")
    end
end

local function persistAchievementState(achievementRef, state)
    if type(Profile.SetAchievementState) ~= "function" then
        return false
    end

    local callOk, persistedState = pcall(Profile.SetAchievementState, achievementRef, state)
    return callOk and type(persistedState) == "table"
end

function Achievements:RebuildIndex()
    local index = {}
    for trigger in pairs(SUPPORTED_TRIGGERS) do
        index[trigger] = {}
    end

    local datasets = type(Registry.GetActivatedDatasets) == "function"
        and Registry:GetActivatedDatasets()
        or {}
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local datasetId = trimText(dataset and dataset.id)
        local achievements = type(dataset and dataset.achievements) == "table"
            and dataset.achievements
            or {}
        for achievementIndex = 1, #achievements do
            local achievement = achievements[achievementIndex]
            local achievementId = trimText(achievement and achievement.id)
            local achievementRef = composeAchievementRef(datasetId, achievementId)
            if achievementRef ~= "" then
                local criteria = type(achievement.criteria) == "table" and achievement.criteria or {}
                for criterionIndex = 1, #criteria do
                    local criterion = criteria[criterionIndex]
                    local trigger = normalizeTrigger(criterion and criterion.trigger)
                    local criterionId = trimText(criterion and criterion.id)
                    if trigger ~= "" and criterionId ~= "" then
                        index[trigger][#index[trigger] + 1] = {
                            achievement = achievement,
                            achievementId = achievementId,
                            achievementRef = achievementRef,
                            dataset = dataset,
                            datasetId = datasetId,
                            criterion = criterion,
                            criterionId = criterionId,
                        }
                    end
                end
            end
        end
    end

    self.CriteriaByTrigger = index
    self.IndexBuilt = true
    self.IndexDatasetSignature = getActivatedDatasetSignature()
    return index
end

function Achievements:EnsureIndex()
    if self.IndexBuilt ~= true
        or self.IndexDatasetSignature ~= getActivatedDatasetSignature()
    then
        return self:RebuildIndex()
    end

    return self.CriteriaByTrigger
end

function Achievements:RefreshIndex()
    return self:RebuildIndex()
end

function Achievements:HandleInventoryChange(payload)
    if type(payload) ~= "table"
        or payload.changeType ~= "add"
        or payload.isCanonicalAdd ~= true
    then
        return {
            trigger = "item_gain",
            updated = 0,
            completed = 0,
        }
    end

    local detail = type(payload.detail) == "table" and payload.detail or {}
    local datasetId = trimText(detail.dataset or detail.datasetId)
    local itemId = trimText(detail.itemId or detail.id)
    local amount = normalizeInteger(detail.actualAddedQuantity, 0)
    if amount <= 0 then
        amount = normalizeInteger(detail.quantity, 0)
    end

    if datasetId == "" or itemId == "" or amount <= 0 then
        return {
            trigger = "item_gain",
            updated = 0,
            completed = 0,
        }
    end

    return self:ProcessTrigger("item_gain", {
        itemRef = ("%s:%s"):format(datasetId, itemId),
        datasetId = datasetId,
        itemId = itemId,
        amount = amount,
        source = "inventory-add",
    })
end

function Achievements:HandleSkillChange(payload)
    if type(payload) ~= "table" then
        return {
            trigger = "skill_gain",
            updated = 0,
            completed = 0,
        }
    end

    local skillRef = trimText(payload.skillRef)
    local previousLevel = normalizeInteger(payload.previousLevel, 0)
    local updatedLevel = normalizeInteger(payload.updatedLevel, 0)
    local actualGain = updatedLevel - previousLevel
    if skillRef == "" or actualGain <= 0 then
        return {
            trigger = "skill_gain",
            updated = 0,
            completed = 0,
        }
    end

    return self:ProcessTrigger("skill_gain", {
        skillRef = skillRef,
        previousLevel = previousLevel,
        updatedLevel = updatedLevel,
        amount = actualGain,
        source = "profile-skill-change",
    })
end

function Achievements:Initialize()
    if self._inventoryListenerId == nil then
        local inventory = Client.Inventory
        if type(inventory) == "table" and type(inventory.RegisterChangeListener) == "function" then
            self._inventoryListenerId = inventory.RegisterChangeListener(function(payload)
                self:HandleInventoryChange(payload)
            end)
        end
    end

    if self._skillListenerId == nil
        and type(Profile) == "table"
        and type(Profile.RegisterSkillChangeListener) == "function"
    then
        self._skillListenerId = Profile.RegisterSkillChangeListener(function(payload)
            self:HandleSkillChange(payload)
        end)
    end

    if type(self.RecoverInProgressRewards) == "function" then
        self:RecoverInProgressRewards()
    end

    return self._inventoryListenerId ~= nil or self._skillListenerId ~= nil
end

function Achievements:RefreshProfileUI()
    refreshProfileUI()
end

function Achievements:Announce(achievementRef)
    local achievement = nil
    if type(Registry.ResolveAchievementReference) == "function" then
        local _, resolvedAchievement = Registry:ResolveAchievementReference(achievementRef)
        achievement = resolvedAchievement
    end
    if type(achievement) ~= "table" then
        local index = self.CriteriaByTrigger or {}
        for _, entries in pairs(index) do
            for indexEntry = 1, #entries do
                if entries[indexEntry].achievementRef == achievementRef then
                    achievement = entries[indexEntry].achievement
                    break
                end
            end
            if achievement then
                break
            end
        end
    end

    if type(achievement) == "table" then
        announceAchievement(achievement)
        return true
    end

    return false
end

function Achievements:_CommitState(achievementRef, achievement, state, options)
    local wasCompleted = state.completedAt ~= nil
    local isComplete = isAchievementComplete(achievement, state)
    local newlyCompleted = false
    if not wasCompleted and isComplete then
        state.completedAt = tonumber(Common.GetNow and Common.GetNow() or 0) or 0
        newlyCompleted = true
    end

    if not persistAchievementState(achievementRef, state) then
        return false, false
    end

    refreshProfileUI()
    if newlyCompleted then
        local rewardTimer = startTiming("Achievement reward-chain", 8, achievementRef)
        local dependentContext = {
            achievementRef = achievementRef,
            source = "achievement-complete",
        }
        if type(options) == "table" and options.announce ~= nil then
            dependentContext.announce = options.announce
        end
        self:ProcessTrigger("achievement_earned", dependentContext)
        if not (type(options) == "table" and options.announce == false) then
            announceAchievement(achievement)
        end

        if type(self.DeliverRewards) == "function" then
            pcall(self.DeliverRewards, self, achievementRef, achievement, {
                newlyCompleted = true,
            })
        end
        if rewardTimer then
            stopTiming(rewardTimer, {
                achievementCriteria = #(achievement.criteria or {}),
                changedAchievements = 1,
            })
        end
    end

    return true, newlyCompleted
end

function Achievements:ProcessTrigger(trigger, context)
    local normalizedTrigger = normalizeTrigger(trigger)
    if normalizedTrigger == "" then
        return {
            trigger = normalizedTrigger,
            updated = 0,
            completed = 0,
        }
    end

    local timer = startTiming("Achievements:ProcessTrigger", 4, normalizedTrigger)
    local index = self:EnsureIndex() or {}
    local entries = index[normalizedTrigger] or {}
    local statesByAchievement = {}
    local entriesByAchievement = {}
    local achievementOrder = {}
    local amount = normalizeInteger(type(context) == "table" and context.amount or 1, 0)
    if amount <= 0 then
        if timer then
            stopTiming(timer, {
                achievementCriteria = #entries,
                changedAchievements = 0,
                completedAchievements = 0,
            })
        end
        return {
            trigger = normalizedTrigger,
            updated = 0,
            completed = 0,
        }
    end

    for indexEntry = 1, #entries do
        local entry = entries[indexEntry]
        if matchesCriterion(entry, normalizedTrigger, context) then
            local achievementRef = entry.achievementRef
            local state = statesByAchievement[achievementRef]
            if not state then
                state = getAchievementState(achievementRef)
                statesByAchievement[achievementRef] = state
                entriesByAchievement[achievementRef] = {}
                achievementOrder[#achievementOrder + 1] = achievementRef
            end

            if state.completedAt == nil then
                local current = normalizeInteger(state.criteria[entry.criterionId], 0)
                local goal = getCriterionGoal(entry.criterion)
                local nextValue = math.min(goal, current + amount)
                if nextValue > current then
                    state.criteria[entry.criterionId] = nextValue
                    entriesByAchievement[achievementRef][#entriesByAchievement[achievementRef] + 1] = entry
                end
            end
        end
    end

    local updated = 0
    local completed = 0
    for indexEntry = 1, #achievementOrder do
        local achievementRef = achievementOrder[indexEntry]
        local state = statesByAchievement[achievementRef]
        local changedEntries = entriesByAchievement[achievementRef]
        if type(changedEntries) == "table" and #changedEntries > 0 then
            local achievement = changedEntries[1].achievement
            local commitOk, newlyCompleted = self:_CommitState(
                achievementRef,
                achievement,
                state,
                context
            )
            if commitOk then
                updated = updated + 1
                if newlyCompleted then
                    completed = completed + 1
                end
            end
        end
    end

    if timer then
        stopTiming(timer, {
            achievementCriteria = #entries,
            changedAchievements = updated,
            completedAchievements = completed,
        })
    end
    return {
        trigger = normalizedTrigger,
        updated = updated,
        completed = completed,
    }
end

function Achievements:HandleRPEKill(context)
    local event = type(context) == "table" and context or {}
    if event.authoritative ~= true
        or event.wasAlive ~= true
        or event.isDead ~= true then
        return {
            trigger = "rpe_kill",
            updated = 0,
            completed = 0,
        }
    end

    local actionOwnerName = normalizeName(event.actionOwnerName)
    local localPlayerName = getLocalPlayerName()
    if actionOwnerName == "" or localPlayerName == "" or actionOwnerName ~= localPlayerName then
        return {
            trigger = "rpe_kill",
            updated = 0,
            completed = 0,
        }
    end

    local result = self:ProcessTrigger("rpe_kill", event)
    local isBoss = event.isBoss
    if isBoss == nil then
        isBoss = isBossEventUnit(event.targetUnit)
    end
    if isBoss ~= true then
        return result
    end

    local bossResult = self:ProcessTrigger("rpe_boss_kill", event)
    result.updated = (tonumber(result.updated) or 0) + (tonumber(bossResult.updated) or 0)
    result.completed = (tonumber(result.completed) or 0) + (tonumber(bossResult.completed) or 0)
    return result
end

local function emptyTriggerResult(trigger)
    return {
        trigger = trigger,
        updated = 0,
        completed = 0,
    }
end

local function processAuthoritativeHealthAchievement(achievements, trigger, context)
    local event = type(context) == "table" and context or {}
    local actionOwnerName = normalizeName(event.actionOwnerName)
    local localPlayerName = getLocalPlayerName()
    local amount = normalizeInteger(event.amount, 0)
    if event.authoritative ~= true
        or actionOwnerName == ""
        or localPlayerName == ""
        or actionOwnerName ~= localPlayerName
        or amount <= 0
    then
        return emptyTriggerResult(trigger)
    end

    event.actionOwnerName = actionOwnerName
    event.amount = amount
    return achievements:ProcessTrigger(trigger, event)
end

function Achievements:HandleRPEDamage(context)
    return processAuthoritativeHealthAchievement(self, "rpe_damage", context)
end

function Achievements:HandleRPEHealing(context)
    return processAuthoritativeHealthAchievement(self, "rpe_healing", context)
end

local function getEventStartIdentity(eventState)
    if type(eventState) ~= "table" then
        return ""
    end

    local channelName = trimText(eventState.channelName)
    local eventId = trimText(eventState.id)
    local startedAt = trimText(eventState.startedAt)
    if channelName == "" and eventId == "" and startedAt == "" then
        return ""
    end

    return table.concat({ channelName, eventId, startedAt }, "\31")
end

function Achievements:HandleRPEEventStart(eventState, startupRuntime)
    if type(eventState) ~= "table" or eventState.active ~= true then
        return {
            trigger = "rpe_event_started",
            updated = 0,
            completed = 0,
        }
    end

    local marker = type(startupRuntime) == "table" and startupRuntime or eventState
    local identity = getEventStartIdentity(eventState)
    if identity ~= "" then
        if marker.achievementStartIdentity == identity then
            return {
                trigger = "rpe_event_started",
                updated = 0,
                completed = 0,
            }
        end
        marker.achievementStartIdentity = identity
    elseif marker.achievementStartProcessed == true then
        return {
            trigger = "rpe_event_started",
            updated = 0,
            completed = 0,
        }
    end
    marker.achievementStartProcessed = true

    return self:ProcessTrigger("rpe_event_started", {
        eventState = eventState,
        eventId = eventState.id,
        eventName = eventState.name,
        source = "rpe-event-start",
        authoritative = true,
    })
end

function Achievements:HandleRPEEventComplete(eventState, reason)
    if type(eventState) ~= "table" then
        return {
            trigger = "rpe_event_complete",
            updated = 0,
            completed = 0,
        }
    end

    local state = eventState
    if state.__rpeAchievementCompletionProcessed == true then
        return {
            trigger = "rpe_event_complete",
            updated = 0,
            completed = 0,
        }
    end

    state.__rpeAchievementCompletionProcessed = true
    return self:ProcessTrigger("rpe_event_complete", {
        eventState = state,
        eventId = state.id,
        eventName = state.name,
        reason = reason,
        source = "rpe-event-end",
    })
end

function Achievements:Grant(achievementRef, options)
    local normalizedRef = trimText(achievementRef)
    if normalizedRef == "" or type(Registry.ResolveAchievementReference) ~= "function" then
        return false, "achievement-unavailable"
    end

    local _, achievement = Registry:ResolveAchievementReference(normalizedRef)
    if type(achievement) ~= "table" then
        return false, "achievement-unavailable"
    end

    local state = getAchievementState(normalizedRef)
    if state.completedAt ~= nil then
        return false, "already-complete"
    end

    local criteria = type(achievement.criteria) == "table" and achievement.criteria or {}
    if #criteria == 0 then
        return false, "achievement-has-no-criteria"
    end

    local hasCriterion = false
    for index = 1, #criteria do
        local criterion = criteria[index]
        local criterionId = trimText(criterion and criterion.id)
        if criterionId ~= "" then
            state.criteria[criterionId] = getCriterionGoal(criterion)
            hasCriterion = true
        end
    end
    if not hasCriterion then
        return false, "achievement-has-no-criteria"
    end

    local commitOk, newlyCompleted = self:_CommitState(normalizedRef, achievement, state, options)
    if not commitOk then
        return false, "profile-persistence-failed"
    end

    return newlyCompleted == true, newlyCompleted and "completed" or "updated"
end

return Achievements
