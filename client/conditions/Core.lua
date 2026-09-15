local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Conditions = Addon.Client.Conditions or {}
Addon.Internal = Addon.Internal or {}

local Conditions = Addon.Client.Conditions
local Client = Addon.Client or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Database = Addon.Internal and Addon.Internal.Database or {}
local Equipment = Profile and Profile.Equipment or {}
local ConditionClass = Database and Database.Classes and Database.Classes.Condition or {}

local function ensureString(value, fallback)
    if value == nil or value == "" then
        return fallback or ""
    end

    return tostring(value)
end

local function lowercase(value)
    return string.lower(ensureString(value))
end

local function parseDatasetQualifiedRef(value)
    local text = ensureString(value)
    local datasetId, entryId = text:match("^([^:]+):(.+)$")
    if ensureString(datasetId) == "" or ensureString(entryId) == "" then
        return nil, nil
    end

    return datasetId, entryId
end

local function sameAuraRef(left, right)
    local leftRef = ensureString(left)
    local rightRef = ensureString(right)
    if leftRef == "" or rightRef == "" then
        return false
    end
    if leftRef == rightRef then
        return true
    end

    local leftDatasetId, leftId = parseDatasetQualifiedRef(leftRef)
    local rightDatasetId, rightId = parseDatasetQualifiedRef(rightRef)
    if leftDatasetId and rightDatasetId then
        return ensureString(leftId) ~= "" and ensureString(leftId) == ensureString(rightId)
    end

    return ensureString(leftId, leftRef) == ensureString(rightId, rightRef)
end

local function appendUniqueRef(list, value)
    local ref = ensureString(value)
    if ref == "" then
        return
    end

    for index = 1, #list do
        if list[index] == ref then
            return
        end
    end

    list[#list + 1] = ref
end

local function anyAuraRefMatches(leftRefs, rightRefs)
    for leftIndex = 1, #(leftRefs or {}) do
        for rightIndex = 1, #(rightRefs or {}) do
            if sameAuraRef(leftRefs[leftIndex], rightRefs[rightIndex]) then
                return true
            end
        end
    end

    return false
end

local function resolveHealthResourceRef()
    if type(Profile.GetHealthResourceRef) == "function" then
        return Profile.GetHealthResourceRef()
    end

    return nil
end

local function buildFailureText(condition, generatedText)
    if type(condition) == "table" then
        local override = ensureString(condition.tooltipTextOverride)
        if override ~= "" then
            return override
        end
    end

    return ensureString(generatedText, "Requirement not met")
end

function Conditions:RegisterCondition(conditionType, contract)
    local normalizedType = lowercase(conditionType)
    if normalizedType == "" or type(contract) ~= "table" then
        return nil
    end

    self.Registry = self.Registry or {}
    contract.type = normalizedType
    self.Registry[normalizedType] = contract
    return contract
end

function Conditions:GetCondition(conditionType)
    local normalizedType = lowercase(conditionType)
    return type(self.Registry) == "table" and self.Registry[normalizedType] or nil
end

function Conditions:CreateConditionDefaults(conditionType)
    if type(ConditionClass) == "table" and type(ConditionClass.CreateDefaults) == "function" then
        return ConditionClass.CreateDefaults(conditionType)
    end

    return nil
end

function Conditions:BuildSpellResourceConditions(spell, options)
    local normalized = {}
    local values = type(options) == "table" and options or {}
    local allowHealth = values.allowHealth == true
    local healthResourceRef = resolveHealthResourceRef()

    for index = 1, #((spell and spell.resourceCosts) or {}) do
        local cost = spell.resourceCosts[index]
        local resourceRef = ensureString(type(cost) == "table" and cost.resourceRef)
        if resourceRef ~= "" then
            local condition = self:NormalizeCondition({
                type = "resource_type",
                resourceRef = resourceRef,
                allowHealth = allowHealth == true or resourceRef == healthResourceRef,
                showOnTooltip = false,
            })
            if condition then
                normalized[#normalized + 1] = condition
            end
        end
    end

    return normalized
end

function Conditions:NormalizeCondition(condition)
    if type(ConditionClass) == "table" and type(ConditionClass.Normalize) == "function" then
        return ConditionClass.Normalize(condition)
    end

    return nil
end

function Conditions:NormalizeList(conditions)
    local normalized = {}
    for index = 1, #(conditions or {}) do
        local entry = self:NormalizeCondition(conditions[index])
        if entry then
            normalized[#normalized + 1] = entry
        end
    end
    return normalized
end

local function findEventUnitById(eventState, eventId)
    local numericEventId = tonumber(eventId) or 0
    if numericEventId <= 0 then
        return nil
    end

    for index = 1, #(eventState and eventState.units or {}) do
        local unit = eventState.units[index]
        if tonumber(unit and unit.eventID) == numericEventId then
            return unit
        end
    end

    return nil
end

local function getPendingSpellTargetUnit(spellRef)
    if type(Client.GetPendingSpellTargetingDisplayState) ~= "function" then
        return nil
    end

    local pending = type(Client.GetPendingSpellTargeting) == "function" and Client:GetPendingSpellTargeting() or nil
    if type(pending) ~= "table" or ensureString(pending.spellRef) ~= ensureString(spellRef) then
        return nil
    end

    local displayState = Client:GetPendingSpellTargetingDisplayState()
    if type(displayState) ~= "table" then
        return nil
    end

    local activeGroup = displayState.activeGroup or nil
    return activeGroup and activeGroup.selectedUnit or nil
end

function Conditions:BuildContext(ownerType, owner, options)
    local values = type(options) == "table" and options or {}
    local eventState = values.eventState
    if eventState == nil and type(Client.GetEventState) == "function" then
        eventState = Client:GetEventState()
    end

    local sessionState = values.sessionState
    if sessionState == nil and type(Client.GetState) == "function" then
        sessionState = Client:GetState()
    end

    local profile = values.profile
    if profile == nil and type(Database.GetActiveProfile) == "function" then
        profile = Database.GetActiveProfile()
    end

    local casterUnit = values.casterUnit
    if casterUnit == nil and type(eventState) == "table" and eventState.active == true and type(Client.ResolveLocalEventUnit) == "function" then
        casterUnit = Client:ResolveLocalEventUnit(eventState)
    end

    local targetUnit = values.targetUnit
    if targetUnit == nil and ownerType == "spell" then
        targetUnit = getPendingSpellTargetUnit(values.ownerRef or values.spellRef)
    end

    local ownerRef = values.ownerRef or values.spellRef or values.itemRef or values.traitRef
    local ownerDatasetId = values.ownerDatasetId
    if ownerDatasetId == nil then
        ownerDatasetId = select(1, parseDatasetQualifiedRef(ownerRef))
    end

    local context = {
        ownerType = ownerType,
        owner = owner,
        ownerRef = ownerRef,
        ownerDatasetId = ownerDatasetId,
        sessionState = sessionState,
        eventState = eventState,
        casterUnit = casterUnit,
        targetUnit = targetUnit,
        profile = profile,
        equipmentScope = values.equipmentScope,
        item = values.item,
        itemRef = values.itemRef,
        spellRef = values.spellRef,
        traitRef = values.traitRef,
    }

    return context
end

function Conditions:GetProfileLevel(context)
    local profile = type(context) == "table" and context.profile or nil
    return math.max(1, math.floor(tonumber(profile and profile.level) or 1))
end

function Conditions:GetProfileClassRef(context)
    local profile = type(context) == "table" and context.profile or nil
    return profile and profile.classRef or nil
end

function Conditions:GetProfileRaceRef(context)
    local profile = type(context) == "table" and context.profile or nil
    return profile and profile.raceRef or nil
end

function Conditions:GetProfileSkillValue(skillRef)
    local row = type(Profile.GetResolvedSkillRow) == "function" and Profile.GetResolvedSkillRow(skillRef) or nil
    return math.max(0, math.floor(tonumber(row and row.value) or 0))
end

function Conditions:GetAllowedSpellResourceRefs(context, condition)
    local refs = {}
    local seen = {}
    local primaryResourceRef = type(Profile.GetPrimaryResourceRef) == "function" and Profile.GetPrimaryResourceRef() or nil
    local specialResourceRef = type(Profile.GetSpecialResourceRef) == "function" and Profile.GetSpecialResourceRef() or nil
    local healthResourceRef = resolveHealthResourceRef()
    local allowHealth = type(condition) == "table" and condition.allowHealth == true

    local function append(ref)
        local normalizedRef = ensureString(ref)
        if normalizedRef ~= "" and not seen[normalizedRef] then
            seen[normalizedRef] = true
            refs[#refs + 1] = normalizedRef
        end
    end

    append(primaryResourceRef)
    append(specialResourceRef)
    if allowHealth == true then
        append(healthResourceRef)
    end

    return refs, ensureString(healthResourceRef)
end

function Conditions:IsAllowedSpellResourceRef(condition, context)
    local resourceRef = ensureString(type(condition) == "table" and condition.resourceRef)
    if resourceRef == "" then
        return false
    end

    local allowedRefs = self:GetAllowedSpellResourceRefs(context, condition)
    for index = 1, #allowedRefs do
        if allowedRefs[index] == resourceRef then
            return true
        end
    end

    return false
end

function Conditions:GetConditionUnit(context, selector)
    local normalizedSelector = lowercase(selector)
    if normalizedSelector == "target" then
        return type(context) == "table" and context.targetUnit or nil
    end

    return type(context) == "table" and context.casterUnit or nil
end

function Conditions:IsUnitDead(unit)
    if type(unit) ~= "table" then
        return false
    end

    local currentHealth = tonumber(unit.currentHealth)
    if currentHealth ~= nil then
        return currentHealth <= 0
    end

    local healthResourceRef = resolveHealthResourceRef()
    if healthResourceRef then
        for index = 1, #(unit.resources or {}) do
            local resource = unit.resources[index]
            if ensureString(resource and resource.resourceRef) == healthResourceRef then
                return math.max(0, tonumber(resource.currentValue) or 0) <= 0
            end
        end
    end

    return unit.dead == true or unit.isDead == true
end

function Conditions:GetUnitHealthPercent(unit)
    if type(unit) ~= "table" then
        return nil
    end

    local currentHealth = tonumber(unit.currentHealth)
    local maximumHealth = tonumber(unit.maxHealth)
    if currentHealth ~= nil and maximumHealth and maximumHealth > 0 then
        return (currentHealth / maximumHealth) * 100
    end

    local healthResourceRef = resolveHealthResourceRef()
    if not healthResourceRef then
        return nil
    end

    for index = 1, #(unit.resources or {}) do
        local resource = unit.resources[index]
        if ensureString(resource and resource.resourceRef) == healthResourceRef then
            local currentValue = tonumber(resource.currentValue) or 0
            local maximumValue = tonumber(resource.maximumValue) or tonumber(resource.maxValue) or 0
            if maximumValue > 0 then
                return (currentValue / maximumValue) * 100
            end
        end
    end

    return nil
end

function Conditions:UnitHasAura(context, unit, auraRef)
    if type(unit) ~= "table" or ensureString(auraRef) == "" then
        return false
    end

    local eventState = type(context) == "table" and context.eventState or nil
    local auraManager = Client and Client.Spellcasting and Client.Spellcasting.AuraManager or nil
    if type(eventState) ~= "table" or eventState.active ~= true or type(auraManager) ~= "table" then
        return false
    end

    local targetEventId = tonumber(unit.eventID) or 0
    if targetEventId <= 0 then
        return false
    end

    local ownerDatasetId = type(context) == "table" and ensureString(context.ownerDatasetId) or ""
    local requiredAuraRefs = {}
    appendUniqueRef(requiredAuraRefs, auraRef)
    if type(auraManager.ResolveAuraDefinition) == "function" then
        local _, _, requiredQualifiedAuraRef = auraManager:ResolveAuraDefinition(auraRef, {
            datasetId = ownerDatasetId ~= "" and ownerDatasetId or nil,
            sourceDatasetId = ownerDatasetId ~= "" and ownerDatasetId or nil,
            spellDatasetId = ownerDatasetId ~= "" and ownerDatasetId or nil,
        })
        appendUniqueRef(requiredAuraRefs, requiredQualifiedAuraRef)
    end

    local auras = nil
    if type(auraManager.GetUnitAuras) == "function" then
        auras = auraManager:GetUnitAuras(Client, eventState, targetEventId) or {}
    elseif type(auraManager.ListAurasForTarget) == "function" then
        auras = auraManager:ListAurasForTarget(eventState, targetEventId) or {}
    end

    if type(auras) == "table" then
        for index = 1, #auras do
            local entry = auras[index]
            local entryAuraRefs = {}
            local entryAuraRef = ensureString(entry and entry.auraRef)
            local entryDatasetId = ensureString(entry and entry.datasetId)
            if entryDatasetId == "" then
                entryDatasetId = select(1, parseDatasetQualifiedRef(entryAuraRef)) or ""
            end
            appendUniqueRef(entryAuraRefs, entryAuraRef)
            local entryQualifiedAuraRef = nil
            if type(auraManager.ResolveAuraDefinition) == "function" then
                _, _, entryQualifiedAuraRef = auraManager:ResolveAuraDefinition(entryAuraRef, {
                    datasetId = entryDatasetId ~= "" and entryDatasetId or nil,
                    sourceDatasetId = entryDatasetId ~= "" and entryDatasetId or nil,
                    spellDatasetId = ownerDatasetId ~= "" and ownerDatasetId or nil,
                })
            end
            appendUniqueRef(entryAuraRefs, entryQualifiedAuraRef)
            if anyAuraRefMatches(entryAuraRefs, requiredAuraRefs) then
                return true
            end
        end
    end

    return false
end

function Conditions:IsTraitActive(traitRef)
    return type(Profile.IsTraitActive) == "function"
        and Profile.IsTraitActive(traitRef) == true
        or false
end

function Conditions:IsMounted(context, selector)
    local unit = self:GetConditionUnit(context, selector)
    if type(unit) == "table" and unit.isPlayer == true then
        return type(Profile.IsMounted) == "function" and Profile.IsMounted() == true or false
    end

    return unit and (unit.isMounted == true or unit.mounted == true) or false
end

function Conditions:FindEquippedItemRows(scope)
    local normalizedScope = lowercase(scope)
    if normalizedScope == "mount" and type(Profile.ListMountEquippedSlots) == "function" then
        return Profile.ListMountEquippedSlots() or {}
    end
    if normalizedScope == "pet" and type(Profile.ListPetEquippedSlots) == "function" then
        return Profile.ListPetEquippedSlots() or {}
    end

    return type(Equipment.ListEquippedSlots) == "function" and Equipment.ListEquippedSlots() or {}
end

function Conditions:ResolveEquippedItemRows(context)
    local scope = type(context) == "table" and context.equipmentScope or nil
    return self:FindEquippedItemRows(scope)
end

function Conditions:ResolveWeaponTypeMatch(context, condition)
    local desiredRefs = type(condition) == "table" and condition.weaponTypeRefs or {}
    if #desiredRefs == 0 then
        return false
    end

    local slotKey = lowercase(type(condition) == "table" and condition.slotKey)
    local equippedRows = self:ResolveEquippedItemRows(context)
    for index = 1, #equippedRows do
        local row = equippedRows[index]
        local currentSlotKey = lowercase(row and row.slotKey)
        local entry = row and row.entry or nil
        local itemRef = entry and entry.itemRef or nil
        local item = row and row.item or nil
        if not item and itemRef and type(Equipment.ResolveItemDefinition) == "function" then
            item = select(1, Equipment.ResolveItemDefinition(itemRef))
        end
        if type(item) == "table" and (slotKey == "" or slotKey == "any" or currentSlotKey == slotKey) then
            local weaponTypeRef = ensureString(item.weaponTypeRef)
            for desiredIndex = 1, #desiredRefs do
                if weaponTypeRef == ensureString(desiredRefs[desiredIndex]) then
                    return true
                end
            end
        end
    end

    return false
end

function Conditions:ResolveItemEquippedMatch(context, condition)
    local desiredWeaponTypeRefs = type(condition) == "table" and condition.weaponTypeRefs or {}
    local requiresShield = type(condition) == "table" and condition.requiresShield == true
    local slotKey = lowercase(type(condition) == "table" and condition.slotKey)
    local equippedRows = self:ResolveEquippedItemRows(context)
    for index = 1, #equippedRows do
        local row = equippedRows[index]
        local currentSlotKey = lowercase(row and row.slotKey)
        local entry = row and row.entry or nil
        local itemRef = ensureString(entry and entry.itemRef)
        if slotKey == "" or slotKey == "any" or currentSlotKey == slotKey then
            local item = row and row.item or nil
            if not item and itemRef and type(Equipment.ResolveItemDefinition) == "function" then
                item = select(1, Equipment.ResolveItemDefinition(itemRef))
            end
            if not requiresShield or lowercase(item and item.armorWeight) == "shield" then
                if #desiredWeaponTypeRefs == 0 then
                    return true
                else
                    local weaponTypeRef = ensureString(item and item.weaponTypeRef)
                    for desiredIndex = 1, #desiredWeaponTypeRefs do
                        if weaponTypeRef == ensureString(desiredWeaponTypeRefs[desiredIndex]) then
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

function Conditions:ResolveResourceName(resourceRef)
    if type(Profile.GetResolvedResourceRow) == "function" then
        local row = Profile.GetResolvedResourceRow(resourceRef)
        if type(row) == "table" and ensureString(row.name) ~= "" then
            return row.name
        end
    end

    if type(Registry.ResolveResourceName) == "function" then
        local name = Registry:ResolveResourceName(resourceRef)
        if ensureString(name) ~= "" then
            return name
        end
    end

    return ensureString(resourceRef, "Resource")
end

function Conditions:ResolveTraitName(traitRef)
    if type(Registry.ResolveTraitName) == "function" then
        local name = Registry:ResolveTraitName(traitRef)
        if ensureString(name) ~= "" then
            return name
        end
    end

    return ensureString(traitRef, "Trait")
end

function Conditions:ResolveAuraName(auraRef)
    local auraManager = Client and Client.Spellcasting and Client.Spellcasting.AuraManager or nil
    if type(auraManager) == "table" and type(auraManager.ResolveAuraDefinition) == "function" then
        local _, aura = auraManager:ResolveAuraDefinition(auraRef, {})
        if type(aura) == "table" and ensureString(aura.name) ~= "" then
            return aura.name
        end
    end

    return ensureString(auraRef, "Aura")
end

function Conditions:ResolveSkillName(skillRef)
    if type(Profile.GetResolvedSkillRow) == "function" then
        local row = Profile.GetResolvedSkillRow(skillRef)
        if type(row) == "table" and ensureString(row.name) ~= "" then
            return row.name
        end
    end
    if type(Registry.ResolveSkillName) == "function" then
        local name = Registry:ResolveSkillName(skillRef)
        if ensureString(name) ~= "" then
            return name
        end
    end
    return ensureString(skillRef, "Skill")
end

function Conditions:ResolveEntryName(reference, collectionKey)
    local ref = ensureString(reference)
    if ref == "" then
        return nil
    end

    local datasetId, entryId = ref:match("^([^:]+):(.+)$")
    local dataset = datasetId and type(Database.GetDatasetByID) == "function" and Database.GetDatasetByID(datasetId) or nil
    local collection = type(dataset) == "table" and dataset[collectionKey] or nil
    for index = 1, #(collection or {}) do
        local entry = collection[index]
        if tostring(entry and entry.id or "") == tostring(entryId) then
            local name = ensureString(entry and entry.name)
            if name ~= "" then
                return name
            end
        end
    end

    return entryId or ref
end

function Conditions:ResolveItemName(itemRef)
    return self:ResolveEntryName(itemRef, "items") or ensureString(itemRef, "Item")
end

function Conditions:ResolveWeaponTypeName(weaponTypeRef)
    if type(Registry.ResolveWeaponTypeName) == "function" then
        local name = Registry:ResolveWeaponTypeName(weaponTypeRef)
        if ensureString(name) ~= "" then
            return name
        end
    end

    return self:ResolveEntryName(weaponTypeRef, "weaponTypes") or ensureString(weaponTypeRef, "Weapon")
end

function Conditions:ResolveConditionText(condition, context)
    local contract = self:GetCondition(type(condition) == "table" and condition.type or nil)
    if type(contract) == "table" and type(contract.BuildTooltipLine) == "function" then
        return buildFailureText(condition, contract.BuildTooltipLine(context, condition))
    end

    return buildFailureText(condition, nil)
end

local function applyInvert(result, condition)
    if type(result) ~= "table" then
        return {
            passed = false,
            failureText = "Requirement not met",
        }
    end

    if type(condition) == "table" and condition.invert == true then
        local originalPassed = result.passed == true
        result.passed = not originalPassed
        if result.passed ~= true then
            result.failureText = buildFailureText(condition, result.invertFailureText or result.failureText)
        end
    end

    if result.passed ~= true and ensureString(result.failureText) == "" then
        result.failureText = buildFailureText(condition, nil)
    end

    return result
end

function Conditions:Evaluate(condition, context)
    local normalized = self:NormalizeCondition(condition)
    if not normalized then
        return {
            passed = false,
            failureText = "Requirement not met",
            condition = condition,
        }
    end

    local contract = self:GetCondition(normalized.type)
    if type(contract) ~= "table" or type(contract.Evaluate) ~= "function" then
        return {
            passed = false,
            failureText = "Requirement not met",
            condition = normalized,
        }
    end

    local result = applyInvert(contract.Evaluate(context, normalized) or {}, normalized)
    result.condition = normalized
    result.failureText = buildFailureText(normalized, result.failureText)
    return result
end

function Conditions:EvaluateList(conditions, context)
    local normalized = self:NormalizeList(conditions)
    local evaluations = {}

    for index = 1, #normalized do
        local result = self:Evaluate(normalized[index], context)
        evaluations[#evaluations + 1] = result
        if result.passed ~= true then
            return {
                passed = false,
                failureText = result.failureText,
                firstFailure = result,
                evaluations = evaluations,
                conditions = normalized,
            }
        end
    end

    return {
        passed = true,
        failureText = "",
        firstFailure = nil,
        evaluations = evaluations,
        conditions = normalized,
    }
end

function Conditions:BuildTooltipLines(conditions, context)
    local lines = {}
    local normalized = self:NormalizeList(conditions)
    for index = 1, #normalized do
        local condition = normalized[index]
        if condition.showOnTooltip == true then
            local evaluation = self:Evaluate(condition, context)
            local text = self:ResolveConditionText(condition, context)
            if text ~= "" then
                lines[#lines + 1] = {
                    text = text,
                    r = evaluation.passed == true and 1 or 0.95,
                    g = evaluation.passed == true and 1 or 0.25,
                    b = evaluation.passed == true and 1 or 0.25,
                    wrap = true,
                }
            end
        end
    end
    return lines
end

return Conditions
