local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.ItemUse = Addon.Client.ItemUse or {}

local Client = Addon.Client
local ItemUse = Client.ItemUse
local Inventory = Client.Inventory or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Database = Addon.Internal and Addon.Internal.Database or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Equipment = Profile.Equipment or {}
local ItemClass = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Item
    or nil

local function trim(value)
    if type(value) ~= "string" then
        return ""
    end
    return value:gsub("^%s+", ""):gsub("%s+$", "")
end

local function composeItemRef(datasetId, itemId)
    local left = trim(tostring(datasetId or ""))
    local right = trim(tostring(itemId or ""))
    if left == "" or right == "" then
        return nil
    end
    return ("%s:%s"):format(left, right)
end

local function isSupportedInventoryItem(item)
    return type(item) == "table" and tostring(item.itemType or "") == "consumable"
end

local function isSupportedEquippedItem(item)
    local itemType = type(item) == "table" and tostring(item.itemType or "") or ""
    return itemType == "weapon" or itemType == "armor"
end

local function isDatasetActive(dataset)
    if type(dataset) ~= "table" or type(dataset.id) ~= "string" or dataset.id == "" then
        return false
    end
    if type(Registry.IsDatasetActivated) == "function" then
        return Registry:IsDatasetActivated(dataset.id) == true
    end
    if type(Database.IsDatasetActivated) == "function" then
        return Database.IsDatasetActivated(dataset.id) == true
    end
    return false
end

local function resolveUseSpell(item)
    local spellRef = trim(item and item.useSpellRef)
    if spellRef == "" then
        return nil, nil, nil, "missing-use-spell"
    end
    if type(Registry.ResolveSpellReference) ~= "function" then
        return nil, nil, nil, "invalid-use-spell"
    end

    local dataset, spell = Registry:ResolveSpellReference(spellRef)
    if type(dataset) ~= "table" or type(spell) ~= "table" then
        return nil, nil, nil, "invalid-use-spell"
    end
    return spellRef, dataset, spell, nil
end

local function getInventorySnapshot()
    if type(Inventory.GetDisplaySnapshot) ~= "function" then
        return {}
    end
    return Inventory.GetDisplaySnapshot() or {}
end

local function getResolvedItemRef(resolved)
    if type(resolved) ~= "table" then
        return nil
    end
    return composeItemRef(
        resolved.datasetId or (resolved.record and resolved.record.dataset),
        resolved.itemId or (resolved.record and resolved.record.id)
    )
end

local function inventoryEntryMatches(resolved, stackIdentity, itemRef)
    if type(resolved) ~= "table" then
        return false
    end
    if tostring(resolved.stackIdentity or "") ~= tostring(stackIdentity or "") then
        return false
    end
    if tostring(getResolvedItemRef(resolved) or "") ~= tostring(itemRef or "") then
        return false
    end
    return math.max(0, math.floor(tonumber(resolved.quantity) or 0)) >= 1
end

local function resolveInventorySource(sourceIndex, expectedStackIdentity, expectedItemRef)
    local requestedIndex = math.floor(tonumber(sourceIndex) or 0)
    local expectedIdentity = trim(tostring(expectedStackIdentity or ""))
    local expectedRef = trim(tostring(expectedItemRef or ""))
    local snapshot = getInventorySnapshot()

    if requestedIndex > 0 then
        for index = 1, #snapshot do
            local resolved = snapshot[index]
            if tonumber(resolved and resolved.sourceIndex) == requestedIndex then
                if expectedIdentity == "" then
                    expectedIdentity = tostring(resolved.stackIdentity or "")
                end
                if expectedRef == "" then
                    expectedRef = tostring(getResolvedItemRef(resolved) or "")
                end
                if inventoryEntryMatches(resolved, expectedIdentity, expectedRef) then
                    return resolved
                end
                break
            end
        end
    end

    if expectedIdentity == "" or expectedRef == "" then
        return nil
    end

    for index = 1, #snapshot do
        local resolved = snapshot[index]
        if inventoryEntryMatches(resolved, expectedIdentity, expectedRef) then
            return resolved
        end
    end
    return nil
end

local function validateInventoryToken(token)
    if type(token) ~= "table" then
        return nil, "stale-source"
    end

    local resolved = resolveInventorySource(token.sourceIndex, token.stackIdentity, token.itemRef)
    if not resolved then
        return nil, "stale-source"
    end
    if resolved.isMissing == true or type(resolved.item) ~= "table" then
        return nil, "missing-item"
    end
    if resolved.isActive ~= true then
        return nil, "inactive-item"
    end
    if not isSupportedInventoryItem(resolved.item) then
        return nil, "invalid-item-type"
    end

    local currentRef = getResolvedItemRef(resolved)
    if tostring(currentRef or "") ~= tostring(token.itemRef or "") then
        return nil, "stale-source"
    end

    local spellRef, spellDataset, spell, spellError = resolveUseSpell(resolved.item)
    if not spellRef then
        return nil, spellError
    end
    if tostring(spellRef) ~= tostring(token.useSpellRef or "") then
        return nil, "stale-source"
    end

    return {
        resolved = resolved,
        item = resolved.item,
        itemRef = currentRef,
        spellRef = spellRef,
        spellDataset = spellDataset,
        spell = spell,
    }, nil
end

local function validateEquipmentToken(token)
    if type(token) ~= "table" then
        return nil, "stale-source"
    end
    if tostring(token.scope or "") ~= "character" then
        return nil, "invalid-item-type"
    end
    if type(Equipment.GetEquippedEntryByScope) ~= "function" then
        return nil, "not-equipped"
    end

    local slotKey = type(Equipment.NormalizeSlotKey) == "function"
        and Equipment.NormalizeSlotKey(token.slotKey)
        or trim(tostring(token.slotKey or ""))
    local entry = Equipment.GetEquippedEntryByScope("character", slotKey)
    if type(entry) ~= "table" then
        return nil, "not-equipped"
    end
    if tostring(entry.itemRef or "") ~= tostring(token.itemRef or "") then
        return nil, "stale-source"
    end
    if type(Equipment.ResolveItemDefinition) ~= "function" then
        return nil, "missing-item"
    end

    local item, dataset = Equipment.ResolveItemDefinition(entry.itemRef)
    if type(item) ~= "table" or type(dataset) ~= "table" then
        return nil, "missing-item"
    end
    if not isDatasetActive(dataset) then
        return nil, "inactive-item"
    end
    if not isSupportedEquippedItem(item) then
        return nil, "invalid-item-type"
    end

    local spellRef, spellDataset, spell, spellError = resolveUseSpell(item)
    if not spellRef then
        return nil, spellError
    end
    if tostring(spellRef) ~= tostring(token.useSpellRef or "") then
        return nil, "stale-source"
    end

    return {
        entry = entry,
        item = item,
        dataset = dataset,
        itemRef = entry.itemRef,
        slotKey = slotKey,
        spellRef = spellRef,
        spellDataset = spellDataset,
        spell = spell,
    }, nil
end

local function validateItemUseSource(sourceContext)
    if type(sourceContext) ~= "table" then
        return false, "stale-source"
    end
    if sourceContext.mode == "inventory" then
        local validated, reason = validateInventoryToken(sourceContext)
        return validated ~= nil, reason
    end
    if sourceContext.mode == "equipment" then
        local validated, reason = validateEquipmentToken(sourceContext)
        return validated ~= nil, reason
    end
    return false, "stale-source"
end

local function commitInventoryUse(token)
    local validated, reason = validateInventoryToken(token)
    if not validated then
        return false, reason
    end

    local resolved = validated.resolved
    local sourceIndex = tonumber(resolved.sourceIndex)
    if not sourceIndex then
        return false, "stale-source"
    end

    if ItemClass
        and type(ItemClass.IsBindOnUse) == "function"
        and ItemClass.IsBindOnUse(validated.item)
        and resolved.soulbound ~= true
    then
        if type(Inventory.BindItem) ~= "function" then
            return false, "stale-source"
        end
        local _, boundIndex = Inventory.BindItem(sourceIndex, 1)
        if not boundIndex then
            return false, "stale-source"
        end
        sourceIndex = boundIndex
    end

    if type(Inventory.RemoveItem) ~= "function" then
        return false, "stale-source"
    end
    local removed = Inventory.RemoveItem(sourceIndex, 1)
    if not removed then
        return false, "stale-source"
    end
    return true
end

local function commitEquipmentUse(token)
    local validated, reason = validateEquipmentToken(token)
    if not validated then
        return false, reason
    end

    local entry = validated.entry
    if ItemClass
        and type(ItemClass.IsBindOnUse) == "function"
        and ItemClass.IsBindOnUse(validated.item)
        and entry.soulbound ~= true
    then
        if type(Equipment.EquipItemInScope) ~= "function" then
            return false, "stale-source"
        end
        local rebound = Equipment.EquipItemInScope(
            "character",
            validated.slotKey,
            entry.itemRef,
            entry.modifications,
            entry.slotRef,
            true
        )
        if not rebound then
            return false, "stale-source"
        end
    end
    return true
end

local function commitItemUseSource(sourceContext)
    if type(sourceContext) ~= "table" then
        return false, "stale-source"
    end
    if sourceContext.mode == "inventory" then
        return commitInventoryUse(sourceContext)
    end
    if sourceContext.mode == "equipment" then
        return commitEquipmentUse(sourceContext)
    end
    return false, "stale-source"
end

-- client_Targeting.lua owns the existing targeting/cast path. Install a thin
-- source-context adapter around that path so every caller still uses the same
-- activation snapshot, targeting UI, and OnSpellcastStart lifecycle.
local function installGenericSpellActivation()
    if Client._itemUseGenericSpellActivationInstalled == true then
        return
    end

    local baseActivateActionBarSpell = Client.ActivateActionBarSpell
    local baseOnSpellcastStart = Client.OnSpellcastStart
    local baseCancelSpellTargeting = Client.CancelSpellTargeting
    local baseResetPendingSpellTargeting = Client.ResetPendingSpellTargeting
    if type(baseActivateActionBarSpell) ~= "function" or type(baseOnSpellcastStart) ~= "function" then
        return
    end

    Client._spellActivationSourceBySnapshot = Client._spellActivationSourceBySnapshot or {}

    local function clearPendingSource(client, snapshot)
        if type(snapshot) == "table" then
            client._spellActivationSourceBySnapshot[snapshot] = nil
        end
        client._pendingImmediateSpellActivationSource = nil
    end

    function Client:OnSpellcastStart(spellRef, castTime, activationSnapshot)
        local source = type(activationSnapshot) == "table" and self._spellActivationSourceBySnapshot[activationSnapshot] or nil
        if source == nil then
            source = self._pendingImmediateSpellActivationSource
        end

        if type(source) == "table" and type(source.onBeforeCastAttempt) == "function" then
            local sourceValid, sourceReason = source.onBeforeCastAttempt(source.sourceContext, spellRef, activationSnapshot)
            if sourceValid ~= true then
                clearPendingSource(self, activationSnapshot)
                return false, sourceReason or "cast-rejected"
            end
        end

        local accepted = baseOnSpellcastStart(self, spellRef, castTime, activationSnapshot)
        if accepted ~= true then
            clearPendingSource(self, activationSnapshot)
            return false, "cast-rejected"
        end

        if type(source) == "table" and type(source.onCastAccepted) == "function" then
            local committed, commitReason = source.onCastAccepted(source.sourceContext, spellRef, activationSnapshot)
            clearPendingSource(self, activationSnapshot)
            if committed == false then
                return false, commitReason or "cast-rejected"
            end
        else
            clearPendingSource(self, activationSnapshot)
        end
        return true
    end

    function Client:ActivateSpellReference(spellRef, options)
        local source = type(options) == "table" and options or {}
        source.spellRef = spellRef

        local previousPending = self.PendingSpellTargeting
        if type(previousPending) == "table" and type(previousPending.activationSnapshot) == "table" then
            self._spellActivationSourceBySnapshot[previousPending.activationSnapshot] = nil
        end

        self._pendingImmediateSpellActivationSource = source
        self._spellActivationStarting = true
        local activated = baseActivateActionBarSpell(self, spellRef)
        self._spellActivationStarting = false
        if activated ~= true then
            self._pendingImmediateSpellActivationSource = nil
            return false, "cast-rejected"
        end

        local pending = self.PendingSpellTargeting
        if type(pending) == "table" and tostring(pending.spellRef or "") == tostring(spellRef or "") then
            pending.activationSource = source
            if type(pending.activationSnapshot) == "table" then
                self._spellActivationSourceBySnapshot[pending.activationSnapshot] = source
            end
            self._pendingImmediateSpellActivationSource = nil
        end
        return true
    end

    function Client:ActivateActionBarSpell(spellRef)
        local activated = self:ActivateSpellReference(spellRef, {
            sourceType = "action_bar",
        })
        return activated == true
    end

    if type(baseCancelSpellTargeting) == "function" then
        function Client:CancelSpellTargeting(reason)
            local pending = self.PendingSpellTargeting
            if type(pending) == "table" and type(pending.activationSnapshot) == "table" then
                self._spellActivationSourceBySnapshot[pending.activationSnapshot] = nil
            end
            if self._spellActivationStarting ~= true then
                self._pendingImmediateSpellActivationSource = nil
            end
            return baseCancelSpellTargeting(self, reason)
        end
    end

    if type(baseResetPendingSpellTargeting) == "function" then
        function Client:ResetPendingSpellTargeting()
            local pending = self.PendingSpellTargeting
            if type(pending) == "table" and type(pending.activationSnapshot) == "table" then
                self._spellActivationSourceBySnapshot[pending.activationSnapshot] = nil
            end
            self._pendingImmediateSpellActivationSource = nil
            return baseResetPendingSpellTargeting(self)
        end
    end

    Client._itemUseGenericSpellActivationInstalled = true
end

installGenericSpellActivation()

function ItemUse:UseInventoryItem(sourceIndex, expectedStackIdentity)
    local resolved = resolveInventorySource(sourceIndex, expectedStackIdentity, nil)
    if not resolved then
        return false, "missing-item"
    end
    if resolved.isMissing == true or type(resolved.item) ~= "table" then
        return false, "missing-item"
    end
    if resolved.isActive ~= true then
        return false, "inactive-item"
    end
    if not isSupportedInventoryItem(resolved.item) then
        return false, "invalid-item-type"
    end

    local itemRef = getResolvedItemRef(resolved)
    local spellRef, _, _, spellError = resolveUseSpell(resolved.item)
    if not spellRef then
        return false, spellError
    end

    local token = {
        mode = "inventory",
        sourceIndex = tonumber(resolved.sourceIndex),
        stackIdentity = tostring(resolved.stackIdentity or ""),
        itemRef = itemRef,
        useSpellRef = spellRef,
    }

    if type(Client.ActivateSpellReference) ~= "function" then
        return false, "cast-rejected"
    end

    return Client:ActivateSpellReference(spellRef, {
        sourceType = "item",
        sourceContext = token,
        onBeforeCastAttempt = validateItemUseSource,
        onCastAccepted = commitItemUseSource,
    })
end

function ItemUse:UseEquippedItem(scope, slotKey)
    local normalizedScope = type(Equipment.NormalizeSlotType) == "function"
        and Equipment.NormalizeSlotType(scope)
        or tostring(scope or "character")
    if normalizedScope ~= "character" then
        return false, "invalid-item-type"
    end

    local normalizedSlotKey = type(Equipment.NormalizeSlotKey) == "function"
        and Equipment.NormalizeSlotKey(slotKey)
        or trim(tostring(slotKey or ""))
    if normalizedSlotKey == "" or type(Equipment.GetEquippedEntryByScope) ~= "function" then
        return false, "not-equipped"
    end

    local entry = Equipment.GetEquippedEntryByScope("character", normalizedSlotKey)
    if type(entry) ~= "table" then
        return false, "not-equipped"
    end
    if type(Equipment.ResolveItemDefinition) ~= "function" then
        return false, "missing-item"
    end

    local item, dataset = Equipment.ResolveItemDefinition(entry.itemRef)
    if type(item) ~= "table" or type(dataset) ~= "table" then
        return false, "missing-item"
    end
    if not isDatasetActive(dataset) then
        return false, "inactive-item"
    end
    if not isSupportedEquippedItem(item) then
        return false, "invalid-item-type"
    end

    local spellRef, _, _, spellError = resolveUseSpell(item)
    if not spellRef then
        return false, spellError
    end

    local token = {
        mode = "equipment",
        scope = "character",
        slotKey = normalizedSlotKey,
        itemRef = entry.itemRef,
        useSpellRef = spellRef,
    }

    if type(Client.ActivateSpellReference) ~= "function" then
        return false, "cast-rejected"
    end

    return Client:ActivateSpellReference(spellRef, {
        sourceType = "item",
        sourceContext = token,
        onBeforeCastAttempt = validateItemUseSource,
        onCastAccepted = commitItemUseSource,
    })
end

return ItemUse
