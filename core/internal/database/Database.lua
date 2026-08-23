local addonName, Addon = ...

Addon.Internal = Addon.Internal or {}

local Database = Addon.Internal.Database or {}
Addon.Internal.Database = Database
local Dependecies = Database.Dependecies or {}

local SCHEMA = {
    profiles = 5,
    rulesets = 1,
    datasets = 15,
    globalSettings = 1,
}

local DATASET_TYPE_VALUES = {
    "general",
    "campaign",
    "crafting",
    "class",
    "items",
}

local DATASET_TYPE_SORT_ORDER = {
    general = 1,
    campaign = 2,
    crafting = 3,
    class = 4,
    items = 5,
}

local DATASET_ENTRY_DEFINITIONS = {
    units = { className = "Unit", singular = "Unit", assignsId = true },
    mounts = { className = "Mount", singular = "Mount", assignsId = true },
    pets = { className = "Pet", singular = "Pet", assignsId = true },
    items = { className = "Item", singular = "Item", assignsId = true },
    spells = { className = "Spell", singular = "Spell", assignsId = true },
    traits = { className = "Trait", singular = "Trait", assignsId = true },
    skills = { className = "Skill", singular = "Skill", assignsId = true },
    stats = { className = "Stat", singular = "Stat", assignsId = true },
    resources = { className = "Resource", singular = "Resource", assignsId = true },
    races = { className = "Race", singular = "Race", assignsId = true },
    classes = { className = "Class", singular = "Class", assignsId = true },
    itemSlots = { className = "ItemSlot", singular = "Item Slot", assignsId = true },
    weaponTypes = { className = "WeaponType", singular = "Weapon Type", assignsId = true },
    damageSchools = { className = "DamageSchool", singular = "Damage School", assignsId = true },
    loot = { className = "Loot", singular = "Loot", assignsId = true },
    recipes = { className = "Recipe", singular = "Recipe", assignsId = true },
    auras = { className = "Aura", singular = "Aura", assignsId = true },
    interactions = { className = "Interaction", singular = "Interaction", assignsId = true },
    achievements = { className = "Achievement", singular = "Achievement", assignsId = true },
    guildSettings = { className = "GuildSetting", singular = "Guild Setting", assignsId = true },
    currencies = { className = "Currency", singular = "Currency", assignsId = true },
}

local function ensureTable(value)
    if type(value) == "table" then
        return value
    end

    return {}
end

local function ensureString(value, fallback)
    if value == nil then
        return fallback or ""
    end

    return tostring(value)
end

local function startsWith(text, prefix)
    return type(text) == "string"
        and type(prefix) == "string"
        and string.sub(text, 1, #prefix) == prefix
end

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, nestedValue in pairs(value) do
        copy[key] = deepCopy(nestedValue)
    end

    return copy
end

local function markConfigurationChanged()
    Addon.Internal = Addon.Internal or {}
    Addon.Internal.ConfigurationRevision = math.max(0, math.floor(tonumber(Addon.Internal.ConfigurationRevision) or 0)) + 1
    return Addon.Internal.ConfigurationRevision
end

local function notifyConfigurationChanged(reason)
    markConfigurationChanged()
    local client = Addon.Client or nil
    if client and type(client.TryDeferLocalConfigurationChanged) == "function" and client:TryDeferLocalConfigurationChanged(reason) then
        return
    end
    if client and type(client.HandleLocalConfigurationChanged) == "function" then
        client:HandleLocalConfigurationChanged(reason)
    end
end

local function applyTable(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then
        return source
    end

    for key in pairs(target) do
        if source[key] == nil then
            target[key] = nil
        end
    end

    for key, value in pairs(source) do
        target[key] = value
    end

    return target
end

local function isIdentifierKey(value)
    return type(value) == "string" and string.match(value, "^[%a_][%w_]*$") ~= nil
end

local function compareSerializedTableKeys(left, right)
    local leftType = type(left)
    local rightType = type(right)
    if leftType == rightType then
        if leftType == "number" then
            return left < right
        end

        return tostring(left) < tostring(right)
    end

    return leftType < rightType
end

local function serializeLuaValue(value)
    local valueType = type(value)
    if valueType == "nil" then
        return "nil"
    end

    if valueType == "boolean" then
        return value and "true" or "false"
    end

    if valueType == "number" then
        return tostring(value)
    end

    if valueType == "string" then
        return string.format("%q", value)
    end

    if valueType ~= "table" then
        error(("Cannot serialize Lua value of type %s."):format(valueType))
    end

    local parts = {}
    local seenKeys = {}
    local arrayLength = #value

    for index = 1, arrayLength do
        parts[#parts + 1] = serializeLuaValue(value[index])
        seenKeys[index] = true
    end

    local extraKeys = {}
    for key in pairs(value) do
        if not seenKeys[key] then
            extraKeys[#extraKeys + 1] = key
        end
    end

    table.sort(extraKeys, compareSerializedTableKeys)

    for index = 1, #extraKeys do
        local key = extraKeys[index]
        local keyText = isIdentifierKey(key)
                and (tostring(key) .. " = ")
            or ("[" .. serializeLuaValue(key) .. "] = ")
        parts[#parts + 1] = keyText .. serializeLuaValue(value[key])
    end

    return "{ " .. table.concat(parts, ", ") .. " }"
end

local function deserializeLuaValue(text)
    if type(text) ~= "string" or text == "" then
        return nil, "Import text is empty."
    end

    local chunkText = "return " .. text
    local globalEnvironment = _G or {}
    local loadStringFunction = rawget(globalEnvironment, "loadstring")
    local loadFunction = rawget(globalEnvironment, "load")
    local loader = loadStringFunction or loadFunction
    if type(loader) ~= "function" then
        return nil, "Lua loader is unavailable."
    end

    local chunk, loadError
    if loader == loadFunction then
        chunk, loadError = loadFunction(chunkText, "RPEngineDatasetImport", "t", {})
    else
        chunk, loadError = loadStringFunction(chunkText)
        if chunk and setfenv then
            setfenv(chunk, {})
        end
    end

    if not chunk then
        return nil, tostring(loadError or "Unable to compile import text.")
    end

    local ok, result = pcall(chunk)
    if not ok then
        return nil, tostring(result or "Unable to execute import text.")
    end

    return result
end

local function rewriteDatasetRefs(value, previousDatasetId, nextDatasetId, seen)
    if previousDatasetId == nextDatasetId then
        return value
    end

    local valueType = type(value)
    if valueType == "string" then
        local prefix = previousDatasetId .. ":"
        if startsWith(value, prefix) then
            return nextDatasetId .. ":" .. string.sub(value, #prefix + 1)
        end

        return value
    end

    if valueType ~= "table" then
        return value
    end

    seen = seen or {}
    if seen[value] then
        return value
    end
    seen[value] = true

    local movedKeys = {}
    for key, nestedValue in pairs(value) do
        local rewrittenKey = rewriteDatasetRefs(key, previousDatasetId, nextDatasetId, seen)
        local rewrittenValue = rewriteDatasetRefs(nestedValue, previousDatasetId, nextDatasetId, seen)
        if rewrittenKey ~= key then
            movedKeys[#movedKeys + 1] = {
                oldKey = key,
                newKey = rewrittenKey,
                value = rewrittenValue,
            }
            value[key] = nil
        else
            value[key] = rewrittenValue
        end
    end

    for index = 1, #movedKeys do
        local move = movedKeys[index]
        value[move.newKey] = move.value
    end

    return value
end

local function resolveCurrentCharacterIdentity()
    if UnitFullName then
        local name, realm = UnitFullName("player")
        if name and name ~= "" then
            realm = realm or (GetRealmName and GetRealmName()) or ""
            if realm ~= "" then
                local characterKey = ("%s-%s"):format(name, realm)
                return characterKey, characterKey, true
            end

            return name, name, true
        end
    end

    if UnitName then
        local name = UnitName("player")
        if name and name ~= "" then
            local realm = (GetRealmName and GetRealmName()) or ""
            if realm ~= "" then
                local characterKey = ("%s-%s"):format(name, realm)
                return characterKey, characterKey, true
            end

            return name, name, true
        end
    end

    return "unknown-player", "Unknown Author", false
end

local function getCharacterKey()
    local characterKey = select(1, resolveCurrentCharacterIdentity())
    return characterKey
end

local function getCharacterDisplayName()
    local _, displayName = resolveCurrentCharacterIdentity()
    return displayName
end

local function resolveCharacterScopedActiveId(root, fieldName)
    local entries = root and ensureTable(root[fieldName]) or {}
    local characterKey = getCharacterKey()
    local exactValue = entries[characterKey]
    if exactValue ~= nil then
        return exactValue, characterKey, false
    end

    if characterKey ~= "unknown-player" and entries["unknown-player"] ~= nil then
        local migratedValue = entries["unknown-player"]
        entries[characterKey] = migratedValue
        entries["unknown-player"] = nil
        root[fieldName] = entries
        return migratedValue, characterKey, true
    end

    return nil, characterKey, false
end

local function normalizeDatasetName(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function getModelDataProvider()
    local data = Addon.Data or {}
    return data.ModelData
end

local function normalizeDatasetState(value, allowed, fallback)
    local candidate = tostring(value or fallback or "")
    for index = 1, #allowed do
        if candidate == allowed[index] then
            return candidate
        end
    end

    return fallback
end

local function normalizeDatasetRecord(record, fallbackId, fallbackName)
    local data = ensureTable(record)
    local datasetId = ensureString(data.id or fallbackId, "")
    local name = normalizeDatasetName(data.name or fallbackName)

    return {
        id = datasetId,
        name = name,
        groupName = ensureString(data.groupName, ""),
        description = ensureString(data.description, ""),
        authorName = ensureString(data.authorName, getCharacterDisplayName()),
        datasetType = normalizeDatasetState(data.datasetType, DATASET_TYPE_VALUES, "general"),
        dependencies = ensureTable(data.dependencies),
        units = ensureTable(data.units),
        mounts = ensureTable(data.mounts),
        pets = ensureTable(data.pets),
        items = ensureTable(data.items),
        spells = ensureTable(data.spells),
        traits = ensureTable(data.traits),
        skills = ensureTable(data.skills),
        stats = ensureTable(data.stats),
        resources = ensureTable(data.resources),
        races = ensureTable(data.races),
        classes = ensureTable(data.classes),
        itemSlots = ensureTable(data.itemSlots),
        weaponTypes = ensureTable(data.weaponTypes),
        damageSchools = ensureTable(data.damageSchools),
        loot = ensureTable(data.loot),
        recipes = ensureTable(data.recipes),
        auras = ensureTable(data.auras),
        interactions = ensureTable(data.interactions),
        achievements = ensureTable(data.achievements),
        guildSettings = ensureTable(data.guildSettings),
        currencies = ensureTable(data.currencies),
    }
end

local function normalizeRulesetRecord(record, fallbackId, fallbackName)
    local data = ensureTable(record)
    local rulesetId = ensureString(data.id or fallbackId, "")
    local name = normalizeDatasetName(data.name or fallbackName)

    return {
        id = rulesetId,
        name = name,
        description = ensureString(data.description, ""),
        authorName = ensureString(data.authorName, getCharacterDisplayName()),
        tagState = normalizeDatasetState(data.tagState, { "standard", "short-term", "long-term" }, "standard"),
        rules = ensureTable(data.rules),
    }
end

local function normalizeRulesetRecordPreservingExtras(record, fallbackId, fallbackName)
    local normalized = normalizeRulesetRecord(record, fallbackId, fallbackName)
    local merged = deepCopy(ensureTable(record))

    -- Preserve unknown ruleset fields during export/import while still normalizing core keys.
    for key, value in pairs(normalized) do
        merged[key] = value
    end

    return merged
end

local function normalizeProfileEquipmentEntry(record)
    local data = ensureTable(record)
    local datasetId = ensureString(data.datasetId, "")
    local itemId = ensureString(data.itemId, "")
    local itemRef = ensureString(data.itemRef, "")
    if itemRef == "" and datasetId ~= "" and itemId ~= "" then
        itemRef = ("%s:%s"):format(datasetId, itemId)
    end

    return {
        datasetId = datasetId,
        itemId = itemId,
        itemRef = itemRef,
        slotRef = ensureString(data.slotRef, ""),
        modifications = deepCopy(ensureTable(data.modifications)),
        soulbound = data.soulbound == true,
    }
end

local function normalizeProfileStatBonuses(record)
    local normalized = {}

    for statRef, bonusValue in pairs(ensureTable(record)) do
        local normalizedStatRef = ensureString(statRef, "")
        if normalizedStatRef ~= "" then
            normalized[normalizedStatRef] = tonumber(bonusValue) or 0
        end
    end

    return normalized
end

local function normalizeProfileCurrencies(record)
    local normalized = {}

    for currencyKey, amount in pairs(ensureTable(record)) do
        local normalizedKey = ensureString(currencyKey, "")
        if normalizedKey ~= "" then
            normalized[normalizedKey] = math.max(0, math.floor(tonumber(amount) or 0))
        end
    end

    return normalized
end

local function normalizeNonNegativeInteger(value)
    local numeric = tonumber(value)
    if numeric == nil or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        return 0
    end

    return math.max(0, math.floor(numeric))
end

local function normalizeProfileAchievementState(record)
    local data = ensureTable(record)
    local criteria = {}

    for criterionId, progress in pairs(ensureTable(data.criteria)) do
        local normalizedCriterionId = ensureString(criterionId, "")
        if normalizedCriterionId ~= "" then
            criteria[normalizedCriterionId] = normalizeNonNegativeInteger(progress)
        end
    end

    local completedAt = tonumber(data.completedAt)
    if completedAt == nil or completedAt ~= completedAt or completedAt == math.huge or completedAt == -math.huge or completedAt < 0 then
        completedAt = nil
    end

    return {
        criteria = criteria,
        completedAt = completedAt,
    }
end

local function normalizeProfileAchievements(record)
    local normalized = {}

    for achievementRef, state in pairs(ensureTable(record)) do
        local normalizedAchievementRef = ensureString(achievementRef, "")
        if normalizedAchievementRef ~= "" then
            normalized[normalizedAchievementRef] = normalizeProfileAchievementState(state)
        end
    end

    return normalized
end

local function normalizeProfileGuildState(record)
    local data = ensureTable(record)
    local normalized = deepCopy(data)
    normalized.byGuild = deepCopy(ensureTable(data.byGuild))
    return normalized
end

local function normalizeProfileSpellbook(record)
    local normalized = {}

    for index = 1, #(record or {}) do
        local spellRef = ensureString(record[index], "")
        if spellRef ~= "" then
            normalized[#normalized + 1] = spellRef
        end
    end

    return normalized
end

local function normalizeProfileRecipebook(record)
    local normalized = {}

    for index = 1, #(record or {}) do
        local recipeRef = ensureString(record[index], "")
        if recipeRef ~= "" then
            normalized[#normalized + 1] = recipeRef
        end
    end

    return normalized
end

local function normalizeProfileRecipeRefList(record)
    local normalized = {}
    local seen = {}

    for index = 1, #(record or {}) do
        local recipeRef = ensureString(record[index], "")
        if recipeRef ~= "" and not seen[recipeRef] then
            normalized[#normalized + 1] = recipeRef
            seen[recipeRef] = true
        end
    end

    return normalized
end

local function normalizeProfileRecipeRefBuckets(record)
    local normalized = {}

    for skillRef, refs in pairs(ensureTable(record)) do
        local normalizedSkillRef = ensureString(skillRef, "")
        if normalizedSkillRef ~= "" then
            normalized[normalizedSkillRef] = normalizeProfileRecipeRefList(refs)
        end
    end

    return normalized
end

local function normalizeProfileRecipeKnowledge(record)
    local data = ensureTable(record)
    return {
        revision = math.max(0, math.floor(tonumber(data.revision) or 0)),
        knownRecipeRefs = normalizeProfileRecipeRefList(data.knownRecipeRefs),
        unknownTrainerRecipeRefs = normalizeProfileRecipeRefList(data.unknownTrainerRecipeRefs),
        knownRecipeRefsBySkill = normalizeProfileRecipeRefBuckets(data.knownRecipeRefsBySkill),
        unknownTrainerRecipeRefsBySkill = normalizeProfileRecipeRefBuckets(data.unknownTrainerRecipeRefsBySkill),
    }
end

local function normalizeProfileSkillLevels(record)
    local normalized = {}

    for skillRef, storedValue in pairs(ensureTable(record)) do
        local normalizedSkillRef = ensureString(skillRef, "")
        if normalizedSkillRef ~= "" then
            normalized[normalizedSkillRef] = math.max(0, math.floor(tonumber(storedValue) or 0))
        end
    end

    return normalized
end

local function normalizeProfileTraits(record)
    local normalized = {}

    for index = 1, #(record or {}) do
        local traitRef = ensureString(record[index], "")
        if traitRef ~= "" then
            normalized[#normalized + 1] = traitRef
        end
    end

    return normalized
end

local function normalizeProfileActiveTraits(record)
    return normalizeProfileTraits(record)
end

local function normalizeProfilePreferredConsumables(record)
    local normalized = {}
    local seen = {}

    for index = 1, #(record or {}) do
        local itemRef = ensureString(record[index], "")
        if itemRef ~= "" and not seen[itemRef] then
            normalized[#normalized + 1] = itemRef
            seen[itemRef] = true
        end
    end

    return normalized
end

local getRulesetStartingLevel

local function normalizeProfileLevel(value)
    return math.max(1, math.floor(tonumber(value) or getRulesetStartingLevel()))
end

local function normalizeProfileActionBar(record)
    local normalized = {}

    for slotIndex, spellRef in pairs(ensureTable(record)) do
        local normalizedSlotIndex = math.floor(tonumber(slotIndex) or 0)
        local normalizedSpellRef = ensureString(spellRef, "")
        if normalizedSlotIndex >= 1 and normalizedSpellRef ~= "" then
            normalized[normalizedSlotIndex] = normalizedSpellRef
        end
    end

    return normalized
end

local function normalizeProfileEquipmentMap(record)
    local normalized = {}

    for slotKey, entry in pairs(ensureTable(record)) do
        local normalizedSlotKey = ensureString(slotKey, "")
        if normalizedSlotKey ~= "" then
            normalized[normalizedSlotKey] = normalizeProfileEquipmentEntry(entry)
        end
    end

    return normalized
end

local function normalizeProfilePetEquipmentMap(record)
    local normalized = {}
    local values = ensureTable(record)

    for _, value in pairs(values) do
        if type(value) == "table" and (value.itemRef ~= nil or value.slotRef ~= nil or value.itemId ~= nil or value.datasetId ~= nil) then
            return normalized
        end
    end

    for petRef, equipmentMap in pairs(values) do
        local normalizedPetRef = ensureString(petRef, "")
        if normalizedPetRef ~= "" then
            normalized[normalizedPetRef] = normalizeProfileEquipmentMap(equipmentMap)
        end
    end

    return normalized
end

local function getProfileEquipmentFieldName(scope)
    local normalizedScope = ensureString(scope, "character")
    if normalizedScope == "mount" then
        return "mountEquipment"
    end
    if normalizedScope == "pet" then
        return "petEquipment"
    end

    return "equipment"
end

local function getActiveProfilePetEquipmentBucket(profile, createIfMissing)
    if type(profile) ~= "table" then
        return nil, ""
    end

    profile.petEquipment = normalizeProfilePetEquipmentMap(profile.petEquipment)
    profile.petRef = ensureString(profile.petRef, "")
    local petRef = profile.petRef
    if petRef == "" then
        return nil, ""
    end

    if createIfMissing == true and profile.petEquipment[petRef] == nil then
        profile.petEquipment[petRef] = {}
    end

    profile.petEquipment[petRef] = normalizeProfileEquipmentMap(profile.petEquipment[petRef])
    return profile.petEquipment[petRef], petRef
end

local function normalizeActionBarMode(value)
    local mode = ensureString(value, "spells")
    if mode == "skills" then
        return "skills"
    end

    return "spells"
end

local function normalizeProfileWidgetAnchor(record)
    local data = ensureTable(record)
    local point = ensureString(data.point, "")
    local relativePoint = ensureString(data.relativePoint, "")
    local x = tonumber(data.x)
    local y = tonumber(data.y)

    if point == "" or relativePoint == "" or x == nil or y == nil then
        return {}
    end

    return {
        point = point,
        relativePoint = relativePoint,
        x = x,
        y = y,
    }
end

local function normalizeProfileWidgets(record)
    local data = ensureTable(record)

    return {
        unlocked = data.unlocked == true,
        actionBar = normalizeProfileWidgetAnchor(data.actionBar),
        actionBarMode = normalizeActionBarMode(data.actionBarMode),
    }
end

local function normalizeProfileResourceDisplay(record)
    local data = ensureTable(record)

    return {
        primaryResourceRef = ensureString(data.primaryResourceRef, ""),
        specialResourceRef = ensureString(data.specialResourceRef, ""),
    }
end

local function normalizeProfileSetupWizard(record)
    local data = ensureTable(record)
    local startingItemRefs = {}
    local seenItemRefs = {}
    local actionBarSpellRefs = {}

    for index = 1, #(data.startingItemRefs or {}) do
        local itemRef = ensureString((data.startingItemRefs or {})[index], "")
        if itemRef ~= "" and not seenItemRefs[itemRef] then
            seenItemRefs[itemRef] = true
            startingItemRefs[#startingItemRefs + 1] = itemRef
        end
    end

    for slotIndex, spellRef in pairs(ensureTable(data.actionBarSpellRefs)) do
        local normalizedSlotIndex = math.floor(tonumber(slotIndex) or 0)
        local normalizedSpellRef = ensureString(spellRef, "")
        if normalizedSlotIndex >= 1 and normalizedSpellRef ~= "" then
            actionBarSpellRefs[normalizedSlotIndex] = normalizedSpellRef
        end
    end

    return {
        raceRef = ensureString(data.raceRef, ""),
        classRef = ensureString(data.classRef, ""),
        startingItemRefs = startingItemRefs,
        actionBarSpellRefs = actionBarSpellRefs,
    }
end

local function isValidProfileSpellRef(spellRef)
    local normalizedRef = ensureString(spellRef, "")
    local datasetId, spellId = normalizedRef:match("^([^:]+):([^:]+)$")
    return datasetId ~= nil and datasetId ~= "" and spellId ~= nil and spellId ~= ""
end

local function isValidProfileSkillRef(skillRef)
    local normalizedRef = ensureString(skillRef, "")
    local datasetId, skillId = normalizedRef:match("^([^:]+):([^:]+)$")
    return datasetId ~= nil and datasetId ~= "" and skillId ~= nil and skillId ~= ""
end

local function isValidProfileRecipeRef(recipeRef)
    local normalizedRef = ensureString(recipeRef, "")
    local datasetId, recipeId = normalizedRef:match("^([^:]+):([^:]+)$")
    return datasetId ~= nil and datasetId ~= "" and recipeId ~= nil and recipeId ~= ""
end

local function normalizeProfileRecord(record, fallbackCharacterKey, fallbackName)
    local data = ensureTable(record)
    local characterKey = ensureString(data.characterKey or fallbackCharacterKey, "")

    return {
        characterKey = characterKey,
        name = ensureString(data.name, fallbackName or getCharacterDisplayName()),
        level = normalizeProfileLevel(data.level),
        raceRef = ensureString(data.raceRef, ""),
        classRef = ensureString(data.classRef, ""),
        mountRef = ensureString(data.mountRef, ""),
        petRef = ensureString(data.petRef, ""),
        mounted = data.mounted == true,
        equipment = normalizeProfileEquipmentMap(data.equipment),
        mountEquipment = normalizeProfileEquipmentMap(data.mountEquipment),
        petEquipment = normalizeProfilePetEquipmentMap(data.petEquipment),
        spellbook = normalizeProfileSpellbook(data.spellbook),
        recipebook = normalizeProfileRecipebook(data.recipebook),
        recipeKnowledge = normalizeProfileRecipeKnowledge(data.recipeKnowledge),
        traits = normalizeProfileTraits(data.traits),
        activeTraits = normalizeProfileActiveTraits(data.activeTraits ~= nil and data.activeTraits or data.traits),
        inactiveTraits = normalizeProfileActiveTraits(data.inactiveTraits),
        skillLevels = normalizeProfileSkillLevels(data.skillLevels),
        preferredConsumables = normalizeProfilePreferredConsumables(data.preferredConsumables),
        actionBar = normalizeProfileActionBar(data.actionBar),
        skillActionBar = normalizeProfileActionBar(data.skillActionBar),
        mountedActionBar = normalizeProfileActionBar(data.mountedActionBar),
        widgets = normalizeProfileWidgets(data.widgets),
        resourceDisplay = normalizeProfileResourceDisplay(data.resourceDisplay),
        setupWizard = normalizeProfileSetupWizard(data.setupWizard),
        statBonuses = normalizeProfileStatBonuses(data.statBonuses),
        currencies = normalizeProfileCurrencies(data.currencies),
        achievements = normalizeProfileAchievements(data.achievements),
        guild = normalizeProfileGuildState(data.guild),
    }
end

getRulesetStartingLevel = function()
    local rulesetLogic = Addon.Internal and Addon.Internal.Ruleset or {}
    local ruleset = rulesetLogic.GetActiveRuleset and rulesetLogic.GetActiveRuleset() or nil
    local ruleDefinition = rulesetLogic.GetRulesetRuleDefinition and rulesetLogic.GetRulesetRuleDefinition("character", "starting_level") or nil
    local rawValue = rulesetLogic.GetRulesetRuleValue and rulesetLogic.GetRulesetRuleValue(ruleset, "character", ruleDefinition) or nil
    return math.max(1, math.floor(tonumber(rawValue) or 1))
end

local function normalizeProfilesCollection(root)
    local profiles = ensureTable(root and root.profiles)
    local normalized = {}

    for key, value in pairs(profiles) do
        local characterKey = ensureString(key, "")
        if characterKey ~= "" then
            local profile = normalizeProfileRecord(value, characterKey, characterKey)
            profile.level = normalizeProfileLevel(value and value.level)
            profile.raceRef = ensureString(value and value.raceRef, "")
            profile.classRef = ensureString(value and value.classRef, "")
            normalized[characterKey] = profile
        end
    end

    root.profiles = normalized
    return root.profiles
end

local function isTableEmpty(value)
    return type(value) ~= "table" or next(value) == nil
end

local function isEmptyProfileGuildState(value)
    if type(value) ~= "table" then
        return true
    end

    for key, nestedValue in pairs(value) do
        if key == "byGuild" then
            if not isTableEmpty(nestedValue) then
                return false
            end
        else
            return false
        end
    end

    return true
end

local function isDefaultProfileRecord(record)
    local profile = normalizeProfileRecord(record, "", "")
    local widgets = normalizeProfileWidgets(profile.widgets)
    local resourceDisplay = normalizeProfileResourceDisplay(profile.resourceDisplay)
    local setupWizard = normalizeProfileSetupWizard(profile.setupWizard)

    return math.max(1, math.floor(tonumber(profile.level) or 1)) == getRulesetStartingLevel()
        and ensureString(profile.raceRef, "") == ""
        and ensureString(profile.classRef, "") == ""
        and ensureString(profile.mountRef, "") == ""
        and ensureString(profile.petRef, "") == ""
        and profile.mounted ~= true
        and isTableEmpty(profile.equipment)
        and isTableEmpty(profile.mountEquipment)
        and isTableEmpty(profile.petEquipment)
        and isTableEmpty(profile.spellbook)
        and isTableEmpty(profile.recipebook)
        and isTableEmpty(profile.recipeKnowledge)
        and isTableEmpty(profile.traits)
        and isTableEmpty(profile.activeTraits)
        and isTableEmpty(profile.inactiveTraits)
        and isTableEmpty(profile.skillLevels)
        and isTableEmpty(profile.preferredConsumables)
        and isTableEmpty(profile.actionBar)
        and isTableEmpty(profile.skillActionBar)
        and isTableEmpty(profile.mountedActionBar)
        and widgets.unlocked ~= true
        and isTableEmpty(widgets.actionBar)
        and ensureString(widgets.actionBarMode, "spells") == "spells"
        and ensureString(resourceDisplay.primaryResourceRef, "") == ""
        and ensureString(resourceDisplay.specialResourceRef, "") == ""
        and ensureString(setupWizard.raceRef, "") == ""
        and ensureString(setupWizard.classRef, "") == ""
        and isTableEmpty(setupWizard.startingItemRefs)
        and isTableEmpty(setupWizard.actionBarSpellRefs)
        and isTableEmpty(profile.statBonuses)
        and isTableEmpty(profile.currencies)
        and isTableEmpty(profile.achievements)
        and isEmptyProfileGuildState(profile.guild)
end

local function migrateUnknownPlayerProfile(root)
    if type(root) ~= "table" then
        return false, false
    end

    local profiles = normalizeProfilesCollection(root)
    local unknownProfile = profiles["unknown-player"]
    if type(unknownProfile) ~= "table" then
        return false, false
    end

    local characterKey, displayName, isStable = resolveCurrentCharacterIdentity()
    if isStable ~= true or characterKey == "" or characterKey == "unknown-player" then
        return false, false
    end

    local authoritativeProfile = profiles[characterKey]
    if type(authoritativeProfile) == "table" then
        if isDefaultProfileRecord(unknownProfile) then
            profiles["unknown-player"] = nil
            return false, true
        end

        return false, false
    end

    local migratedProfile = normalizeProfileRecord(unknownProfile, characterKey, displayName)
    migratedProfile.characterKey = characterKey
    migratedProfile.name = displayName ~= "" and displayName or ensureString(migratedProfile.name, displayName)
    profiles[characterKey] = migratedProfile
    profiles["unknown-player"] = nil
    return true, true
end

local function nextDatasetEntryId(entries, collectionKey, definition)
    local alphabet = "abcdefghijklmnopqrstuvwxyz0123456789"
    local seen = {}

    for index = 1, #entries do
        local candidate = entries[index] and tostring(entries[index].id or "") or ""
        if candidate ~= "" then
            seen[candidate] = true
        end
    end

    local function randomToken()
        local chars = {}
        for charIndex = 1, 8 do
            local offset = math.random(1, #alphabet)
            chars[charIndex] = alphabet:sub(offset, offset)
        end
        return table.concat(chars)
    end

    for _ = 1, 128 do
        local token = randomToken()
        if not seen[token] then
            return token
        end
    end

    local prefix = string.lower(tostring((definition and definition.singular) or collectionKey or "entry")):sub(1, 1)
    local suffix = 1
    while true do
        local fallback = ("%s%07d"):format(prefix ~= "" and prefix or "e", suffix)
        if not seen[fallback] then
            return fallback
        end
        suffix = suffix + 1
    end
end

local function buildSeededUnitFields(dataset)
    local seededSpells = {}
    local seededStats = {}
    local seededResources = {}
    local datasetId = ensureString(dataset and dataset.id, "")

    if datasetId == "" then
        return seededSpells, seededStats, seededResources
    end

    for index = 1, #ensureTable(dataset and dataset.spells) do
        local spell = dataset.spells[index]
        if spell and spell.id and spell.seedNPCSpell == true then
            seededSpells[#seededSpells + 1] = ("%s:%s"):format(datasetId, spell.id)
        end
    end

    for index = 1, #ensureTable(dataset and dataset.stats) do
        local stat = dataset.stats[index]
        if stat and stat.id and stat.seedNPCStat == true then
            seededStats[#seededStats + 1] = {
                statRef = ("%s:%s"):format(datasetId, stat.id),
                value = tonumber(stat.baseValue) or 0,
            }
        end
    end

    for index = 1, #ensureTable(dataset and dataset.resources) do
        local resource = dataset.resources[index]
        if resource and resource.id and resource.seedNPCResource == true then
            seededResources[#seededResources + 1] = {
                resourceRef = ("%s:%s"):format(datasetId, resource.id),
                value = tonumber(resource.baseValue) or 0,
                perPlayer = 0,
            }
        end
    end

    return seededSpells, seededStats, seededResources
end

local function createDatasetEntryRecord(dataset, collectionKey, entryId)
    local definition = DATASET_ENTRY_DEFINITIONS[collectionKey] or {}
    local classes = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes or {}
    local classObject = classes and classes[definition.className] or nil
    local entry = nil

    if classObject and classObject.New then
        entry = classObject:New()
    else
        entry = {}
    end

    if definition.assignsId then
        entry.id = entryId
    end

    if entry.name == nil or entry.name == "" then
        entry.name = ("New %s"):format(definition.singular or "Entry")
    end

    if collectionKey == "units" then
        entry.spells, entry.stats, entry.resources = buildSeededUnitFields(dataset)
    end

    if classObject and classObject.ToTable then
        return classObject.ToTable(entry)
    end

    return entry
end

local function getDatasetEntryClassObject(collectionKey)
    local definition = DATASET_ENTRY_DEFINITIONS[collectionKey] or {}
    local classes = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes or {}
    return classes and classes[definition.className] or nil
end

local function normalizeDatasetEntryRecord(dataset, collectionKey, data, entryId)
    local definition = DATASET_ENTRY_DEFINITIONS[collectionKey]
    if not definition then
        return nil
    end

    local classObject = getDatasetEntryClassObject(collectionKey)
    local normalized = nil

    if classObject and type(classObject.FromTable) == "function" then
        local instance = classObject.FromTable(deepCopy(type(data) == "table" and data or {}))
        if classObject.ToTable then
            normalized = classObject.ToTable(instance)
        else
            normalized = deepCopy(instance)
        end
    elseif classObject and type(classObject.New) == "function" then
        local instance = classObject:New(deepCopy(type(data) == "table" and data or {}))
        if classObject.ToTable then
            normalized = classObject.ToTable(instance)
        else
            normalized = deepCopy(instance)
        end
    else
        normalized = createDatasetEntryRecord(dataset, collectionKey, entryId)
        if type(data) == "table" then
            applyTable(normalized, deepCopy(data))
        end
    end

    if type(normalized) ~= "table" then
        return nil
    end

    if definition.assignsId then
        normalized.id = ensureString(entryId ~= nil and entryId or normalized.id, "")
    else
        normalized.id = normalized.id
    end

    if normalized.name == nil or normalized.name == "" then
        normalized.name = ("New %s"):format(definition.singular or "Entry")
    end

    return normalized
end

local function findDatasetEntry(dataset, collectionKey, entryIdOrIndex)
    local definition = DATASET_ENTRY_DEFINITIONS[collectionKey]
    if not dataset or not definition then
        return nil, nil
    end

    local entries = ensureTable(dataset[collectionKey])
    local numericIndex = tonumber(entryIdOrIndex)
    if numericIndex and entries[numericIndex] ~= nil then
        return entries[numericIndex], numericIndex
    end

    local targetId = ensureString(entryIdOrIndex, "")
    if targetId == "" then
        return nil, nil
    end

    for index = 1, #entries do
        local entry = entries[index]
        if entry and ensureString(entry.id, "") == targetId then
            return entry, index
        end
    end

    return nil, nil
end

local FIXED_ID_LENGTH = 8
local GUID_ALPHABET = "0123456789abcdef"
local guidRandomSeeded = false
local randomSeedFunction = type(math) == "table" and rawget(math, "randomseed") or nil
local randomFunction = type(math) == "table" and rawget(math, "random") or nil

local function ensureGuidRandomSeed()
    if guidRandomSeeded then
        return
    end

    local seed = 0
    if type(time) == "function" then
        seed = time()
    elseif type(GetServerTime) == "function" then
        seed = GetServerTime()
    end

    if type(GetTimePreciseSec) == "function" then
        seed = seed + math.floor(GetTimePreciseSec() * 1000)
    elseif type(GetTime) == "function" then
        seed = seed + math.floor(GetTime() * 1000)
    end

    if type(UnitGUID) == "function" then
        local playerGuid = tostring(UnitGUID("player") or "")
        for index = 1, #playerGuid do
            seed = seed + string.byte(playerGuid, index)
        end
    end

    if type(randomSeedFunction) == "function" then
        randomSeedFunction(seed)
    else
        guidRandomSeeded = true
        return
    end

    if type(randomFunction) == "function" then
        randomFunction()
        randomFunction()
        randomFunction()
    end

    guidRandomSeeded = true
end

local function generateGuidLikeId()
    ensureGuidRandomSeed()

    local chars = {}
    for index = 1, FIXED_ID_LENGTH do
        local offset = type(randomFunction) == "function" and randomFunction(1, #GUID_ALPHABET) or ((index - 1) % #GUID_ALPHABET) + 1
        chars[index] = GUID_ALPHABET:sub(offset, offset)
    end

    return table.concat(chars)
end

local function nextCollectionId(root, collectionKey)
    local collection = ensureTable(root and root[collectionKey])

    for _ = 1, 256 do
        local candidate = generateGuidLikeId()
        if collection[candidate] == nil then
            return candidate
        end
    end

    root.nextId = math.max(1, tonumber(root.nextId) or 1)
    while true do
        local fallback = ("%08x"):format(root.nextId)
        root.nextId = root.nextId + 1
        if collection[fallback] == nil then
            return fallback
        end
    end
end

local function nextRulesetId(root)
    return nextCollectionId(root, "rulesets")
end

local function nextDatasetId(root)
    return nextCollectionId(root, "datasets")
end

local function normalizeDatasetsCollection(root)
    local rawDatasets = ensureTable(root and root.datasets)
    local normalized = {}
    root.nextId = math.max(1, tonumber(root.nextId) or 1)

    for key, value in pairs(rawDatasets) do
        local fallbackId = nil
        local fallbackName = nil

        if type(key) == "string" and key ~= "" then
            fallbackId = key
            fallbackName = key
        end

        local dataset = normalizeDatasetRecord(value, fallbackId, fallbackName)
        if dataset.id == "" then
            dataset.id = fallbackId or ""
        end

        if dataset.id == "" then
            while true do
                local placeholderId = nextDatasetId(root)
                if normalized[placeholderId] == nil then
                    dataset.id = placeholderId
                    break
                end
            end
        end

        if type(value) == "table" then
            dataset = applyTable(value, dataset)
        end

        normalized[dataset.id] = dataset
    end

    root.datasets = normalized
    return root.datasets
end

local function normalizeRulesetsCollection(root)
    local rawRulesets = ensureTable(root and root.rulesets)
    local normalized = {}
    root.nextId = math.max(1, tonumber(root.nextId) or 1)

    for key, value in pairs(rawRulesets) do
        local fallbackId = nil
        local fallbackName = nil

        if type(key) == "string" and key ~= "" then
            fallbackId = key
            fallbackName = key
        end

        local ruleset = normalizeRulesetRecord(value, fallbackId, fallbackName)
        if ruleset.id == "" then
            ruleset.id = fallbackId or ""
        end

        if ruleset.id == "" then
            while true do
                local placeholderId = nextRulesetId(root)
                if normalized[placeholderId] == nil then
                    ruleset.id = placeholderId
                    break
                end
            end
        end

        if type(value) == "table" then
            ruleset = applyTable(value, ruleset)
        end

        normalized[ruleset.id] = ruleset
    end

    root.rulesets = normalized
    return root.rulesets
end

local function normalizeActivatedDatasets(root)
    local values = ensureTable(root and root.activatedDatasets)
    local normalized = {}
    local seen = {}
    local datasets = ensureTable(root and root.datasets)

    for key, value in pairs(values) do
        local datasetId = ""
        if type(key) == "number" then
            datasetId = ensureString(value, "")
        elseif value == true then
            datasetId = ensureString(key, "")
        end

        if datasetId ~= "" and datasets[datasetId] ~= nil and not seen[datasetId] then
            normalized[#normalized + 1] = datasetId
            seen[datasetId] = true
        end
    end

    root.activatedDatasets = normalized
    return root.activatedDatasets
end

local function ensureSection(rootName, schemaVersion, defaults)
    local root = ensureTable(_G[rootName])
    _G[rootName] = root

    root._schema = math.max(tonumber(root._schema) or 0, schemaVersion)

    for key, defaultValue in pairs(defaults) do
        if root[key] == nil then
            if type(defaultValue) == "table" then
                root[key] = {}
            else
                root[key] = defaultValue
            end
        end
    end

    return root
end

function Database.EnsureProfiles()
    local profiles = ensureSection("RPEngineProfilesDB", SCHEMA.profiles, {
        currentByChar = {},
        profiles = {},
    })

    profiles.lastLFRPChannel = nil
    profiles.currentByChar = nil
    normalizeProfilesCollection(profiles)
    migrateUnknownPlayerProfile(profiles)

    Database.Profiles = profiles
    return profiles
end

function Database.GetActiveProfile()
    local root = Database.EnsureProfiles()
    local characterKey = getCharacterKey()
    local profile = root.profiles and root.profiles[characterKey] or nil
    if type(profile) == "table" then
        profile.characterKey = characterKey
        if characterKey ~= "unknown-player" and ensureString(profile.name, "") == "" then
            profile.name = getCharacterDisplayName()
        end
    end
    return profile
end

function Database.GetOrCreateActiveProfile()
    local root = Database.EnsureProfiles()
    local characterKey = getCharacterKey()
    local profile = root.profiles and root.profiles[characterKey] or nil

    if profile then
        return profile
    end

    profile = normalizeProfileRecord({
        characterKey = characterKey,
        name = getCharacterDisplayName(),
        level = getRulesetStartingLevel(),
        raceRef = "",
        classRef = "",
        mountRef = "",
        petRef = "",
        mounted = false,
        equipment = {},
        mountEquipment = {},
        petEquipment = {},
        spellbook = {},
        recipebook = {},
        recipeKnowledge = {},
        traits = {},
        activeTraits = {},
        inactiveTraits = {},
        skillLevels = {},
        preferredConsumables = {},
        actionBar = {},
        skillActionBar = {},
        mountedActionBar = {},
        widgets = {},
        resourceDisplay = {},
        setupWizard = {},
        statBonuses = {},
        currencies = {},
        achievements = {},
        guild = { byGuild = {} },
    }, characterKey, getCharacterDisplayName())
    root.profiles[characterKey] = profile
    return profile
end

function Database.ResolveCurrentCharacterIdentity()
    return resolveCurrentCharacterIdentity()
end

function Database.IsCurrentCharacterIdentityStable()
    return select(3, resolveCurrentCharacterIdentity()) == true
end

function Database.UpdateActiveProfile(mutator)
    local profile = Database.GetOrCreateActiveProfile()
    if type(mutator) == "function" then
        mutator(profile)
    end
    return profile
end

function Database.SetProfileEquipmentSlot(slotKey, equippedEntry)
    local normalizedSlotKey = ensureString(slotKey, "")
    if normalizedSlotKey == "" then
        return nil
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.equipment = ensureTable(profile.equipment)
    profile.equipment[normalizedSlotKey] = normalizeProfileEquipmentEntry(equippedEntry)
    notifyConfigurationChanged("profile-equipment")
    return profile.equipment[normalizedSlotKey]
end

function Database.ListProfileEquipmentByScope(scope)
    local profile = Database.GetOrCreateActiveProfile()
    local normalizedScope = ensureString(scope, "character")
    local source = nil

    if normalizedScope == "pet" then
        source = select(1, getActiveProfilePetEquipmentBucket(profile, false)) or {}
    else
        local fieldName = getProfileEquipmentFieldName(normalizedScope)
        profile[fieldName] = normalizeProfileEquipmentMap(profile[fieldName])
        source = profile[fieldName]
    end

    local copy = {}
    for slotKey, entry in pairs(source) do
        copy[slotKey] = normalizeProfileEquipmentEntry(entry)
    end

    return copy
end

function Database.SetProfileEquipmentSlotByScope(scope, slotKey, equippedEntry)
    local normalizedSlotKey = ensureString(slotKey, "")
    if normalizedSlotKey == "" then
        return nil
    end

    local normalizedScope = ensureString(scope, "character")
    local profile = Database.GetOrCreateActiveProfile()
    local target = nil

    if normalizedScope == "pet" then
        target = select(1, getActiveProfilePetEquipmentBucket(profile, true))
        if not target then
            return nil
        end
    else
        local fieldName = getProfileEquipmentFieldName(normalizedScope)
        profile[fieldName] = normalizeProfileEquipmentMap(profile[fieldName])
        target = profile[fieldName]
    end

    target[normalizedSlotKey] = normalizeProfileEquipmentEntry(equippedEntry)
    notifyConfigurationChanged(("profile-%s-equipment"):format(normalizedScope))
    return target[normalizedSlotKey]
end

function Database.ClearProfileEquipmentSlotByScope(scope, slotKey)
    local normalizedSlotKey = ensureString(slotKey, "")
    if normalizedSlotKey == "" then
        return false
    end

    local normalizedScope = ensureString(scope, "character")
    local profile = Database.GetOrCreateActiveProfile()
    local target = nil

    if normalizedScope == "pet" then
        target = select(1, getActiveProfilePetEquipmentBucket(profile, false))
        if not target then
            return false
        end
    else
        local fieldName = getProfileEquipmentFieldName(normalizedScope)
        profile[fieldName] = normalizeProfileEquipmentMap(profile[fieldName])
        target = profile[fieldName]
    end

    local existed = target[normalizedSlotKey] ~= nil
    target[normalizedSlotKey] = nil
    if existed then
        notifyConfigurationChanged(("profile-%s-equipment"):format(normalizedScope))
    end
    return existed
end

function Database.ClearProfileEquipmentSlot(slotKey)
    local normalizedSlotKey = ensureString(slotKey, "")
    if normalizedSlotKey == "" then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.equipment = ensureTable(profile.equipment)
    local existed = profile.equipment[normalizedSlotKey] ~= nil
    profile.equipment[normalizedSlotKey] = nil
    if existed then
        notifyConfigurationChanged("profile-equipment")
    end
    return existed
end

function Database.ListProfileMountEquipment()
    return Database.ListProfileEquipmentByScope("mount")
end

function Database.SetProfileMountEquipmentSlot(slotKey, equippedEntry)
    return Database.SetProfileEquipmentSlotByScope("mount", slotKey, equippedEntry)
end

function Database.ClearProfileMountEquipmentSlot(slotKey)
    return Database.ClearProfileEquipmentSlotByScope("mount", slotKey)
end

function Database.ListProfileSpellbook()
    local profile = Database.GetOrCreateActiveProfile()
    profile.spellbook = normalizeProfileSpellbook(profile.spellbook)

    local spellbook = {}
    for index = 1, #profile.spellbook do
        spellbook[index] = profile.spellbook[index]
    end

    return spellbook
end

function Database.ListProfileRecipebook()
    local profile = Database.GetOrCreateActiveProfile()
    profile.recipebook = normalizeProfileRecipebook(profile.recipebook)

    local recipebook = {}
    for index = 1, #profile.recipebook do
        recipebook[index] = profile.recipebook[index]
    end

    return recipebook
end

function Database.GetProfileRecipeKnowledge()
    local profile = Database.GetOrCreateActiveProfile()
    profile.recipeKnowledge = normalizeProfileRecipeKnowledge(profile.recipeKnowledge)
    return deepCopy(profile.recipeKnowledge)
end

function Database.SetProfileRecipeKnowledge(recipeKnowledge)
    local profile = Database.GetOrCreateActiveProfile()
    profile.recipeKnowledge = normalizeProfileRecipeKnowledge(recipeKnowledge)
    return deepCopy(profile.recipeKnowledge)
end

local function isValidProfileTraitRef(traitRef)
    local normalizedRef = ensureString(traitRef, "")
    local datasetId, traitId = normalizedRef:match("^([^:]+):([^:]+)$")
    return datasetId ~= nil and datasetId ~= "" and traitId ~= nil and traitId ~= ""
end

function Database.ListProfileTraits()
    local profile = Database.GetOrCreateActiveProfile()
    profile.traits = normalizeProfileTraits(profile.traits)

    local traits = {}
    for index = 1, #profile.traits do
        traits[index] = profile.traits[index]
    end

    return traits
end

function Database.ListProfileActiveTraits()
    local profile = Database.GetOrCreateActiveProfile()
    profile.activeTraits = normalizeProfileActiveTraits(profile.activeTraits)

    local traits = {}
    for index = 1, #profile.activeTraits do
        traits[index] = profile.activeTraits[index]
    end

    return traits
end

function Database.ListProfileInactiveTraits()
    local profile = Database.GetOrCreateActiveProfile()
    profile.inactiveTraits = normalizeProfileActiveTraits(profile.inactiveTraits)

    local traits = {}
    for index = 1, #profile.inactiveTraits do
        traits[index] = profile.inactiveTraits[index]
    end

    return traits
end

function Database.ListProfilePreferredConsumables()
    local profile = Database.GetOrCreateActiveProfile()
    profile.preferredConsumables = normalizeProfilePreferredConsumables(profile.preferredConsumables)

    local consumables = {}
    for index = 1, #profile.preferredConsumables do
        consumables[index] = profile.preferredConsumables[index]
    end

    return consumables
end

function Database.AddProfileTrait(traitRef)
    local normalizedRef = ensureString(traitRef, "")
    if not isValidProfileTraitRef(normalizedRef) then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.traits = normalizeProfileTraits(profile.traits)

    for index = 1, #profile.traits do
        if profile.traits[index] == normalizedRef then
            return false
        end
    end

    profile.traits[#profile.traits + 1] = normalizedRef
    notifyConfigurationChanged("profile-traits")
    return true
end

function Database.AddProfileActiveTrait(traitRef)
    local normalizedRef = ensureString(traitRef, "")
    if not isValidProfileTraitRef(normalizedRef) then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.activeTraits = normalizeProfileActiveTraits(profile.activeTraits)

    for index = 1, #profile.activeTraits do
        if profile.activeTraits[index] == normalizedRef then
            return false
        end
    end

    profile.activeTraits[#profile.activeTraits + 1] = normalizedRef
    notifyConfigurationChanged("profile-active-traits")
    return true
end

function Database.AddProfileInactiveTrait(traitRef)
    local normalizedRef = ensureString(traitRef, "")
    if not isValidProfileTraitRef(normalizedRef) then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.inactiveTraits = normalizeProfileActiveTraits(profile.inactiveTraits)

    for index = 1, #profile.inactiveTraits do
        if profile.inactiveTraits[index] == normalizedRef then
            return false
        end
    end

    profile.inactiveTraits[#profile.inactiveTraits + 1] = normalizedRef
    notifyConfigurationChanged("profile-inactive-traits")
    return true
end

function Database.AddProfilePreferredConsumable(itemRef)
    local normalizedRef = ensureString(itemRef, "")
    if normalizedRef == "" then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.preferredConsumables = normalizeProfilePreferredConsumables(profile.preferredConsumables)

    for index = 1, #profile.preferredConsumables do
        if profile.preferredConsumables[index] == normalizedRef then
            return false
        end
    end

    profile.preferredConsumables[#profile.preferredConsumables + 1] = normalizedRef
    notifyConfigurationChanged("profile-preferred-consumables")
    return true
end

function Database.RemoveProfileTrait(traitRef)
    local normalizedRef = ensureString(traitRef, "")
    if normalizedRef == "" then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.traits = normalizeProfileTraits(profile.traits)
    profile.activeTraits = normalizeProfileActiveTraits(profile.activeTraits)
    profile.inactiveTraits = normalizeProfileActiveTraits(profile.inactiveTraits)

    for index = 1, #profile.traits do
        if profile.traits[index] == normalizedRef then
            table.remove(profile.traits, index)
            for activeIndex = #profile.activeTraits, 1, -1 do
                if profile.activeTraits[activeIndex] == normalizedRef then
                    table.remove(profile.activeTraits, activeIndex)
                end
            end
            for inactiveIndex = #profile.inactiveTraits, 1, -1 do
                if profile.inactiveTraits[inactiveIndex] == normalizedRef then
                    table.remove(profile.inactiveTraits, inactiveIndex)
                end
            end
            notifyConfigurationChanged("profile-traits")
            return true
        end
    end

    return false
end

function Database.RemoveProfileTraitAt(index)
    local removeIndex = tonumber(index)
    if not removeIndex then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.traits = normalizeProfileTraits(profile.traits)
    profile.activeTraits = normalizeProfileActiveTraits(profile.activeTraits)
    profile.inactiveTraits = normalizeProfileActiveTraits(profile.inactiveTraits)
    if profile.traits[removeIndex] == nil then
        return false
    end

    local removedRef = profile.traits[removeIndex]
    table.remove(profile.traits, removeIndex)
    for activeIndex = #profile.activeTraits, 1, -1 do
        if profile.activeTraits[activeIndex] == removedRef then
            table.remove(profile.activeTraits, activeIndex)
        end
    end
    for inactiveIndex = #profile.inactiveTraits, 1, -1 do
        if profile.inactiveTraits[inactiveIndex] == removedRef then
            table.remove(profile.inactiveTraits, inactiveIndex)
        end
    end
    notifyConfigurationChanged("profile-traits")
    return true
end

function Database.RemoveProfileActiveTrait(traitRef)
    local normalizedRef = ensureString(traitRef, "")
    if normalizedRef == "" then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.activeTraits = normalizeProfileActiveTraits(profile.activeTraits)

    for index = 1, #profile.activeTraits do
        if profile.activeTraits[index] == normalizedRef then
            table.remove(profile.activeTraits, index)
            notifyConfigurationChanged("profile-active-traits")
            return true
        end
    end

    return false
end

function Database.RemoveProfileInactiveTrait(traitRef)
    local normalizedRef = ensureString(traitRef, "")
    if normalizedRef == "" then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.inactiveTraits = normalizeProfileActiveTraits(profile.inactiveTraits)

    for index = 1, #profile.inactiveTraits do
        if profile.inactiveTraits[index] == normalizedRef then
            table.remove(profile.inactiveTraits, index)
            notifyConfigurationChanged("profile-inactive-traits")
            return true
        end
    end

    return false
end

function Database.RemoveProfilePreferredConsumable(itemRef)
    local normalizedRef = ensureString(itemRef, "")
    if normalizedRef == "" then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.preferredConsumables = normalizeProfilePreferredConsumables(profile.preferredConsumables)

    for index = 1, #profile.preferredConsumables do
        if profile.preferredConsumables[index] == normalizedRef then
            table.remove(profile.preferredConsumables, index)
            notifyConfigurationChanged("profile-preferred-consumables")
            return true
        end
    end

    return false
end

function Database.AddProfileSpellbookSpell(spellRef)
    local normalizedRef = ensureString(spellRef, "")
    if not isValidProfileSpellRef(normalizedRef) then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.spellbook = normalizeProfileSpellbook(profile.spellbook)

    for index = 1, #profile.spellbook do
        if profile.spellbook[index] == normalizedRef then
            return false
        end
    end

    profile.spellbook[#profile.spellbook + 1] = normalizedRef
    notifyConfigurationChanged("profile-spellbook")
    return true
end

function Database.AddProfileRecipebookRecipe(recipeRef)
    local normalizedRef = ensureString(recipeRef, "")
    if not isValidProfileRecipeRef(normalizedRef) then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.recipebook = normalizeProfileRecipebook(profile.recipebook)

    for index = 1, #profile.recipebook do
        if profile.recipebook[index] == normalizedRef then
            return false
        end
    end

    profile.recipebook[#profile.recipebook + 1] = normalizedRef
    notifyConfigurationChanged("profile-recipebook")
    return true
end

function Database.RemoveProfileSpellbookSpell(spellRef)
    local normalizedRef = ensureString(spellRef, "")
    if normalizedRef == "" then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.spellbook = normalizeProfileSpellbook(profile.spellbook)

    for index = 1, #profile.spellbook do
        if profile.spellbook[index] == normalizedRef then
            table.remove(profile.spellbook, index)
            notifyConfigurationChanged("profile-spellbook")
            return true
        end
    end

    return false
end

function Database.RemoveProfileRecipebookRecipe(recipeRef)
    local normalizedRef = ensureString(recipeRef, "")
    if normalizedRef == "" then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.recipebook = normalizeProfileRecipebook(profile.recipebook)

    for index = 1, #profile.recipebook do
        if profile.recipebook[index] == normalizedRef then
            table.remove(profile.recipebook, index)
            notifyConfigurationChanged("profile-recipebook")
            return true
        end
    end

    return false
end

function Database.RemoveProfileSpellbookSpellAt(index)
    local removeIndex = tonumber(index)
    if not removeIndex then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.spellbook = normalizeProfileSpellbook(profile.spellbook)
    if profile.spellbook[removeIndex] == nil then
        return false
    end

    table.remove(profile.spellbook, removeIndex)
    notifyConfigurationChanged("profile-spellbook")
    return true
end

function Database.RemoveProfileRecipebookRecipeAt(index)
    local removeIndex = tonumber(index)
    if not removeIndex then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.recipebook = normalizeProfileRecipebook(profile.recipebook)
    if profile.recipebook[removeIndex] == nil then
        return false
    end

    table.remove(profile.recipebook, removeIndex)
    notifyConfigurationChanged("profile-recipebook")
    return true
end

function Database.ListProfileActionBar()
    local profile = Database.GetOrCreateActiveProfile()
    profile.actionBar = normalizeProfileActionBar(profile.actionBar)

    local actionBar = {}
    for slotIndex, spellRef in pairs(profile.actionBar) do
        actionBar[slotIndex] = spellRef
    end

    return actionBar
end

function Database.ListProfileSkillActionBar()
    local profile = Database.GetOrCreateActiveProfile()
    profile.skillActionBar = normalizeProfileActionBar(profile.skillActionBar)

    local actionBar = {}
    for slotIndex, skillRef in pairs(profile.skillActionBar) do
        actionBar[slotIndex] = skillRef
    end

    return actionBar
end

function Database.ListProfileMountedActionBar()
    local profile = Database.GetOrCreateActiveProfile()
    profile.mountedActionBar = normalizeProfileActionBar(profile.mountedActionBar)

    local actionBar = {}
    for slotIndex, spellRef in pairs(profile.mountedActionBar) do
        actionBar[slotIndex] = spellRef
    end

    return actionBar
end

function Database.GetProfileWidgetsUnlocked()
    local profile = Database.GetOrCreateActiveProfile()
    profile.widgets = normalizeProfileWidgets(profile.widgets)
    return profile.widgets.unlocked == true
end

function Database.GetProfileActionBarMode()
    local profile = Database.GetOrCreateActiveProfile()
    profile.widgets = normalizeProfileWidgets(profile.widgets)
    return normalizeActionBarMode(profile.widgets.actionBarMode)
end

function Database.GetProfileMountRef()
    local profile = Database.GetOrCreateActiveProfile()
    profile.mountRef = ensureString(profile.mountRef, "")
    return profile.mountRef ~= "" and profile.mountRef or nil
end

function Database.SetProfileMountRef(mountRef)
    local normalizedRef = ensureString(mountRef, "")
    local profile = Database.GetOrCreateActiveProfile()
    profile.mountRef = normalizedRef
    if normalizedRef == "" and profile.mounted == true then
        profile.mounted = false
    end
    notifyConfigurationChanged("profile-mount")
    return normalizedRef ~= "" and normalizedRef or nil
end

function Database.GetProfilePetRef()
    local profile = Database.GetOrCreateActiveProfile()
    profile.petRef = ensureString(profile.petRef, "")
    return profile.petRef ~= "" and profile.petRef or nil
end

function Database.SetProfilePetRef(petRef)
    local normalizedRef = ensureString(petRef, "")
    local profile = Database.GetOrCreateActiveProfile()
    profile.petRef = normalizedRef
    notifyConfigurationChanged("profile-pet")
    return normalizedRef ~= "" and normalizedRef or nil
end

function Database.GetProfileMounted()
    local profile = Database.GetOrCreateActiveProfile()
    profile.mounted = profile.mounted == true
    return profile.mounted == true
end

function Database.SetProfileMounted(mounted)
    local profile = Database.GetOrCreateActiveProfile()
    profile.mounted = mounted == true and ensureString(profile.mountRef, "") ~= ""
    notifyConfigurationChanged("profile-mounted")
    return profile.mounted == true
end

function Database.SetProfileWidgetsUnlocked(unlocked)
    local profile = Database.GetOrCreateActiveProfile()
    profile.widgets = normalizeProfileWidgets(profile.widgets)

    local normalizedUnlocked = unlocked == true
    if profile.widgets.unlocked == normalizedUnlocked then
        return normalizedUnlocked
    end

    profile.widgets.unlocked = normalizedUnlocked
    notifyConfigurationChanged("profile-widgets-unlocked")
    return normalizedUnlocked
end

function Database.SetProfileActionBarMode(mode)
    local profile = Database.GetOrCreateActiveProfile()
    profile.widgets = normalizeProfileWidgets(profile.widgets)

    local normalizedMode = normalizeActionBarMode(mode)
    if profile.widgets.actionBarMode == normalizedMode then
        return normalizedMode
    end

    profile.widgets.actionBarMode = normalizedMode
    notifyConfigurationChanged("profile-action-bar-mode")
    return normalizedMode
end

function Database.GetProfilePrimaryResourceRef()
    local profile = Database.GetOrCreateActiveProfile()
    profile.resourceDisplay = normalizeProfileResourceDisplay(profile.resourceDisplay)

    local resourceRef = ensureString(profile.resourceDisplay.primaryResourceRef, "")
    if resourceRef == "" then
        return nil
    end

    return resourceRef
end

function Database.GetProfileLevel()
    local profile = Database.GetOrCreateActiveProfile()
    profile.level = normalizeProfileLevel(profile.level)
    return profile.level
end

function Database.SetProfileLevel(level)
    local profile = Database.GetOrCreateActiveProfile()
    local normalizedLevel = normalizeProfileLevel(level)
    if profile.level == normalizedLevel then
        return normalizedLevel
    end

    profile.level = normalizedLevel
    notifyConfigurationChanged("profile-level")
    return normalizedLevel
end

function Database.GetProfileRaceRef()
    local profile = Database.GetOrCreateActiveProfile()
    local raceRef = ensureString(profile.raceRef, "")
    if raceRef == "" then
        return nil
    end

    return raceRef
end

function Database.SetProfileRaceRef(raceRef)
    local profile = Database.GetOrCreateActiveProfile()
    local normalizedRaceRef = ensureString(raceRef, "")
    if profile.raceRef == normalizedRaceRef then
        return normalizedRaceRef ~= "" and normalizedRaceRef or nil
    end

    profile.raceRef = normalizedRaceRef
    notifyConfigurationChanged("profile-race")
    return normalizedRaceRef ~= "" and normalizedRaceRef or nil
end

function Database.GetProfileClassRef()
    local profile = Database.GetOrCreateActiveProfile()
    local classRef = ensureString(profile.classRef, "")
    if classRef == "" then
        return nil
    end

    return classRef
end

function Database.SetProfileClassRef(classRef)
    local profile = Database.GetOrCreateActiveProfile()
    local normalizedClassRef = ensureString(classRef, "")
    if profile.classRef == normalizedClassRef then
        return normalizedClassRef ~= "" and normalizedClassRef or nil
    end

    profile.classRef = normalizedClassRef
    notifyConfigurationChanged("profile-class")
    return normalizedClassRef ~= "" and normalizedClassRef or nil
end

function Database.SetProfilePrimaryResourceRef(resourceRef)
    local profile = Database.GetOrCreateActiveProfile()
    profile.resourceDisplay = normalizeProfileResourceDisplay(profile.resourceDisplay)

    local normalizedResourceRef = ensureString(resourceRef, "")
    if profile.resourceDisplay.primaryResourceRef == normalizedResourceRef then
        return normalizedResourceRef ~= "" and normalizedResourceRef or nil
    end

    profile.resourceDisplay.primaryResourceRef = normalizedResourceRef
    notifyConfigurationChanged("profile-primary-resource")
    return normalizedResourceRef ~= "" and normalizedResourceRef or nil
end

function Database.GetProfileSpecialResourceRef()
    local profile = Database.GetOrCreateActiveProfile()
    profile.resourceDisplay = normalizeProfileResourceDisplay(profile.resourceDisplay)

    local resourceRef = ensureString(profile.resourceDisplay.specialResourceRef, "")
    if resourceRef == "" then
        return nil
    end

    return resourceRef
end

function Database.SetProfileSpecialResourceRef(resourceRef)
    local profile = Database.GetOrCreateActiveProfile()
    profile.resourceDisplay = normalizeProfileResourceDisplay(profile.resourceDisplay)

    local normalizedResourceRef = ensureString(resourceRef, "")
    if profile.resourceDisplay.specialResourceRef == normalizedResourceRef then
        return normalizedResourceRef ~= "" and normalizedResourceRef or nil
    end

    profile.resourceDisplay.specialResourceRef = normalizedResourceRef
    notifyConfigurationChanged("profile-special-resource")
    return normalizedResourceRef ~= "" and normalizedResourceRef or nil
end

function Database.GetProfileSetupWizardState()
    local profile = Database.GetOrCreateActiveProfile()
    profile.setupWizard = normalizeProfileSetupWizard(profile.setupWizard)

    return normalizeProfileSetupWizard(profile.setupWizard)
end

function Database.SetProfileSetupWizardState(state)
    local profile = Database.GetOrCreateActiveProfile()
    profile.setupWizard = normalizeProfileSetupWizard(state)
    notifyConfigurationChanged("profile-setup-wizard")
    return normalizeProfileSetupWizard(profile.setupWizard)
end

function Database.GetProfileActionBarAnchor()
    local profile = Database.GetOrCreateActiveProfile()
    profile.widgets = normalizeProfileWidgets(profile.widgets)

    local anchor = normalizeProfileWidgetAnchor(profile.widgets.actionBar)
    if not anchor.point or not anchor.relativePoint then
        return nil
    end

    return {
        point = anchor.point,
        relativePoint = anchor.relativePoint,
        x = anchor.x,
        y = anchor.y,
    }
end

function Database.SetProfileActionBarAnchor(anchor)
    local normalizedAnchor = normalizeProfileWidgetAnchor(anchor)
    if not normalizedAnchor.point or not normalizedAnchor.relativePoint then
        return nil
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.widgets = normalizeProfileWidgets(profile.widgets)
    profile.widgets.actionBar = normalizedAnchor
    notifyConfigurationChanged("profile-action-bar-anchor")

    return {
        point = normalizedAnchor.point,
        relativePoint = normalizedAnchor.relativePoint,
        x = normalizedAnchor.x,
        y = normalizedAnchor.y,
    }
end

function Database.GetProfileActionBarSpell(slotIndex)
    local normalizedSlotIndex = math.floor(tonumber(slotIndex) or 0)
    if normalizedSlotIndex < 1 then
        return nil
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.actionBar = normalizeProfileActionBar(profile.actionBar)
    return profile.actionBar[normalizedSlotIndex]
end

function Database.GetProfileActionBarSkill(slotIndex)
    local normalizedSlotIndex = math.floor(tonumber(slotIndex) or 0)
    if normalizedSlotIndex < 1 then
        return nil
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.skillActionBar = normalizeProfileActionBar(profile.skillActionBar)
    return profile.skillActionBar[normalizedSlotIndex]
end

function Database.GetProfileMountedActionBarSpell(slotIndex)
    local normalizedSlotIndex = math.floor(tonumber(slotIndex) or 0)
    if normalizedSlotIndex < 1 then
        return nil
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.mountedActionBar = normalizeProfileActionBar(profile.mountedActionBar)
    return profile.mountedActionBar[normalizedSlotIndex]
end

function Database.FindProfileActionBarSlotBySpell(spellRef)
    local normalizedRef = ensureString(spellRef, "")
    if normalizedRef == "" then
        return nil
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.actionBar = normalizeProfileActionBar(profile.actionBar)

    for slotIndex, boundSpellRef in pairs(profile.actionBar) do
        if boundSpellRef == normalizedRef then
            return slotIndex
        end
    end

    return nil
end

function Database.FindProfileActionBarSlotBySkill(skillRef)
    local normalizedRef = ensureString(skillRef, "")
    if normalizedRef == "" then
        return nil
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.skillActionBar = normalizeProfileActionBar(profile.skillActionBar)

    for slotIndex, boundSkillRef in pairs(profile.skillActionBar) do
        if boundSkillRef == normalizedRef then
            return slotIndex
        end
    end

    return nil
end

function Database.FindProfileMountedActionBarSlotBySpell(spellRef)
    local normalizedRef = ensureString(spellRef, "")
    if normalizedRef == "" then
        return nil
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.mountedActionBar = normalizeProfileActionBar(profile.mountedActionBar)

    for slotIndex, boundSpellRef in pairs(profile.mountedActionBar) do
        if boundSpellRef == normalizedRef then
            return slotIndex
        end
    end

    return nil
end

function Database.BindProfileActionBarSpell(slotIndex, spellRef)
    local normalizedSlotIndex = math.floor(tonumber(slotIndex) or 0)
    local normalizedRef = ensureString(spellRef, "")
    if normalizedSlotIndex < 1 or not isValidProfileSpellRef(normalizedRef) then
        return nil
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.actionBar = normalizeProfileActionBar(profile.actionBar)

    for existingSlotIndex, boundSpellRef in pairs(profile.actionBar) do
        if boundSpellRef == normalizedRef then
            profile.actionBar[existingSlotIndex] = nil
        end
    end

    profile.actionBar[normalizedSlotIndex] = normalizedRef
    notifyConfigurationChanged("profile-action-bar")
    return normalizedSlotIndex
end

function Database.BindProfileActionBarSkill(slotIndex, skillRef)
    local normalizedSlotIndex = math.floor(tonumber(slotIndex) or 0)
    local normalizedRef = ensureString(skillRef, "")
    if normalizedSlotIndex < 1 or not isValidProfileSkillRef(normalizedRef) then
        return nil
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.skillActionBar = normalizeProfileActionBar(profile.skillActionBar)

    for existingSlotIndex, boundSkillRef in pairs(profile.skillActionBar) do
        if boundSkillRef == normalizedRef then
            profile.skillActionBar[existingSlotIndex] = nil
        end
    end

    profile.skillActionBar[normalizedSlotIndex] = normalizedRef
    notifyConfigurationChanged("profile-skill-action-bar")
    return normalizedSlotIndex
end

function Database.BindProfileMountedActionBarSpell(slotIndex, spellRef)
    local normalizedSlotIndex = math.floor(tonumber(slotIndex) or 0)
    local normalizedRef = ensureString(spellRef, "")
    if normalizedSlotIndex < 1 or not isValidProfileSpellRef(normalizedRef) then
        return nil
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.mountedActionBar = normalizeProfileActionBar(profile.mountedActionBar)

    for existingSlotIndex, boundSpellRef in pairs(profile.mountedActionBar) do
        if boundSpellRef == normalizedRef then
            if existingSlotIndex == normalizedSlotIndex then
                return normalizedSlotIndex
            end
            profile.mountedActionBar[existingSlotIndex] = nil
        end
    end

    profile.mountedActionBar[normalizedSlotIndex] = normalizedRef
    notifyConfigurationChanged("profile-mounted-action-bar")
    return normalizedSlotIndex
end

function Database.ClearProfileActionBarSlot(slotIndex)
    local normalizedSlotIndex = math.floor(tonumber(slotIndex) or 0)
    if normalizedSlotIndex < 1 then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.actionBar = normalizeProfileActionBar(profile.actionBar)
    local existed = profile.actionBar[normalizedSlotIndex] ~= nil
    profile.actionBar[normalizedSlotIndex] = nil
    if existed then
        notifyConfigurationChanged("profile-action-bar")
    end
    return existed
end

function Database.ClearProfileSkillActionBarSlot(slotIndex)
    local normalizedSlotIndex = math.floor(tonumber(slotIndex) or 0)
    if normalizedSlotIndex < 1 then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.skillActionBar = normalizeProfileActionBar(profile.skillActionBar)
    local existed = profile.skillActionBar[normalizedSlotIndex] ~= nil
    profile.skillActionBar[normalizedSlotIndex] = nil
    if existed then
        notifyConfigurationChanged("profile-skill-action-bar")
    end
    return existed
end

function Database.ClearProfileMountedActionBarSlot(slotIndex)
    local normalizedSlotIndex = math.floor(tonumber(slotIndex) or 0)
    if normalizedSlotIndex < 1 then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.mountedActionBar = normalizeProfileActionBar(profile.mountedActionBar)
    local existed = profile.mountedActionBar[normalizedSlotIndex] ~= nil
    profile.mountedActionBar[normalizedSlotIndex] = nil
    if existed then
        notifyConfigurationChanged("profile-mounted-action-bar")
    end
    return existed
end

function Database.UnbindProfileActionBarSpell(spellRef)
    local normalizedRef = ensureString(spellRef, "")
    if normalizedRef == "" then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.actionBar = normalizeProfileActionBar(profile.actionBar)

    for slotIndex, boundSpellRef in pairs(profile.actionBar) do
        if boundSpellRef == normalizedRef then
            profile.actionBar[slotIndex] = nil
            notifyConfigurationChanged("profile-action-bar")
            return true
        end
    end

    return false
end

function Database.UnbindProfileActionBarSkill(skillRef)
    local normalizedRef = ensureString(skillRef, "")
    if normalizedRef == "" then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.skillActionBar = normalizeProfileActionBar(profile.skillActionBar)

    for slotIndex, boundSkillRef in pairs(profile.skillActionBar) do
        if boundSkillRef == normalizedRef then
            profile.skillActionBar[slotIndex] = nil
            notifyConfigurationChanged("profile-skill-action-bar")
            return true
        end
    end

    return false
end

function Database.UnbindProfileMountedActionBarSpell(spellRef)
    local normalizedRef = ensureString(spellRef, "")
    if normalizedRef == "" then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.mountedActionBar = normalizeProfileActionBar(profile.mountedActionBar)

    for slotIndex, boundSpellRef in pairs(profile.mountedActionBar) do
        if boundSpellRef == normalizedRef then
            profile.mountedActionBar[slotIndex] = nil
            notifyConfigurationChanged("profile-mounted-action-bar")
            return true
        end
    end

    return false
end

function Database.GetProfileStatBonus(statRef)
    local normalizedStatRef = ensureString(statRef, "")
    if normalizedStatRef == "" then
        return 0
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.statBonuses = normalizeProfileStatBonuses(profile.statBonuses)
    return tonumber(profile.statBonuses[normalizedStatRef]) or 0
end

function Database.SetProfileStatBonus(statRef, value)
    local normalizedStatRef = ensureString(statRef, "")
    if normalizedStatRef == "" then
        return nil
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.statBonuses = normalizeProfileStatBonuses(profile.statBonuses)
    profile.statBonuses[normalizedStatRef] = tonumber(value) or 0
    return profile.statBonuses[normalizedStatRef]
end

function Database.ClearProfileStatBonus(statRef)
    local normalizedStatRef = ensureString(statRef, "")
    if normalizedStatRef == "" then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.statBonuses = normalizeProfileStatBonuses(profile.statBonuses)
    local existed = profile.statBonuses[normalizedStatRef] ~= nil
    profile.statBonuses[normalizedStatRef] = nil
    return existed
end

function Database.ListProfileCurrencies()
    local profile = Database.GetOrCreateActiveProfile()
    profile.currencies = normalizeProfileCurrencies(profile.currencies)

    local copy = {}
    for currencyKey, amount in pairs(profile.currencies) do
        copy[currencyKey] = amount
    end

    return copy
end

function Database.GetProfileCurrencyAmount(currencyKey)
    local normalizedCurrencyKey = ensureString(currencyKey, "")
    if normalizedCurrencyKey == "" then
        return 0
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.currencies = normalizeProfileCurrencies(profile.currencies)
    return math.max(0, math.floor(tonumber(profile.currencies[normalizedCurrencyKey]) or 0))
end

function Database.SetProfileCurrencyAmount(currencyKey, amount)
    local normalizedCurrencyKey = ensureString(currencyKey, "")
    if normalizedCurrencyKey == "" then
        return nil
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.currencies = normalizeProfileCurrencies(profile.currencies)
    local normalizedAmount = math.max(0, math.floor(tonumber(amount) or 0))
    profile.currencies[normalizedCurrencyKey] = normalizedAmount
    notifyConfigurationChanged("profile-currency")
    return normalizedAmount
end

function Database.ClearProfileCurrencyAmount(currencyKey)
    local normalizedCurrencyKey = ensureString(currencyKey, "")
    if normalizedCurrencyKey == "" then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.currencies = normalizeProfileCurrencies(profile.currencies)
    local existed = profile.currencies[normalizedCurrencyKey] ~= nil
    profile.currencies[normalizedCurrencyKey] = nil
    if existed then
        notifyConfigurationChanged("profile-currency")
    end
    return existed
end

function Database.ListProfileAchievementStates()
    local profile = Database.GetOrCreateActiveProfile()
    profile.achievements = normalizeProfileAchievements(profile.achievements)
    return deepCopy(profile.achievements)
end

function Database.GetProfileAchievementState(achievementRef)
    local normalizedAchievementRef = ensureString(achievementRef, "")
    if normalizedAchievementRef == "" then
        return nil
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.achievements = normalizeProfileAchievements(profile.achievements)
    return deepCopy(profile.achievements[normalizedAchievementRef])
end

function Database.SetProfileAchievementState(achievementRef, state)
    local normalizedAchievementRef = ensureString(achievementRef, "")
    if normalizedAchievementRef == "" then
        return nil
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.achievements = normalizeProfileAchievements(profile.achievements)
    profile.achievements[normalizedAchievementRef] = normalizeProfileAchievementState(state)
    notifyConfigurationChanged("profile-achievements")
    return deepCopy(profile.achievements[normalizedAchievementRef])
end

function Database.ClearProfileAchievementState(achievementRef)
    local normalizedAchievementRef = ensureString(achievementRef, "")
    if normalizedAchievementRef == "" then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.achievements = normalizeProfileAchievements(profile.achievements)
    local existed = profile.achievements[normalizedAchievementRef] ~= nil
    profile.achievements[normalizedAchievementRef] = nil
    if existed then
        notifyConfigurationChanged("profile-achievements")
    end
    return existed
end

function Database.GetProfileGuildState()
    local profile = Database.GetOrCreateActiveProfile()
    profile.guild = normalizeProfileGuildState(profile.guild)
    return deepCopy(profile.guild)
end

function Database.SetProfileGuildState(state)
    local profile = Database.GetOrCreateActiveProfile()
    profile.guild = normalizeProfileGuildState(state)
    notifyConfigurationChanged("profile-guild")
    return deepCopy(profile.guild)
end

function Database.ListProfileSkillLevels()
    local profile = Database.GetOrCreateActiveProfile()
    profile.skillLevels = normalizeProfileSkillLevels(profile.skillLevels)

    local copy = {}
    for skillRef, value in pairs(profile.skillLevels) do
        copy[skillRef] = value
    end

    return copy
end

function Database.GetProfileSkillLevel(skillRef)
    local normalizedSkillRef = ensureString(skillRef, "")
    if normalizedSkillRef == "" then
        return 0
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.skillLevels = normalizeProfileSkillLevels(profile.skillLevels)
    return math.max(0, math.floor(tonumber(profile.skillLevels[normalizedSkillRef]) or 0))
end

function Database.SetProfileSkillLevel(skillRef, value)
    local normalizedSkillRef = ensureString(skillRef, "")
    if normalizedSkillRef == "" then
        return nil
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.skillLevels = normalizeProfileSkillLevels(profile.skillLevels)
    profile.skillLevels[normalizedSkillRef] = math.max(0, math.floor(tonumber(value) or 0))
    notifyConfigurationChanged("profile-skills")
    return profile.skillLevels[normalizedSkillRef]
end

function Database.ClearProfileSkillLevel(skillRef)
    local normalizedSkillRef = ensureString(skillRef, "")
    if normalizedSkillRef == "" then
        return false
    end

    local profile = Database.GetOrCreateActiveProfile()
    profile.skillLevels = normalizeProfileSkillLevels(profile.skillLevels)
    local existed = profile.skillLevels[normalizedSkillRef] ~= nil
    profile.skillLevels[normalizedSkillRef] = nil
    if existed then
        notifyConfigurationChanged("profile-skills")
    end
    return existed
end

function Database.EnsureRulesets()
    local rulesets = ensureSection("RPEngineRulesetDB", SCHEMA.rulesets, {
        rulesets = {},
        activeByChar = {},
        nextId = 1,
    })

    if type(rulesets.currentByChar) == "table" and next(rulesets.activeByChar or {}) == nil then
        rulesets.activeByChar = ensureTable(rulesets.currentByChar)
    end
    rulesets.currentByChar = nil
    rulesets.activeByChar = ensureTable(rulesets.activeByChar)
    normalizeRulesetsCollection(rulesets)
    Database.Rulesets = rulesets
    return rulesets
end

function Database.EnsureDatasets()
    local datasets = ensureSection("RPEngineDatasetDB", SCHEMA.datasets, {
        datasets = {},
        activeByChar = {},
        activatedDatasets = {},
        nextId = 1,
    })

    datasets.currentByChar = nil
    datasets.activeByChar = ensureTable(datasets.activeByChar)
    normalizeDatasetsCollection(datasets)
    normalizeActivatedDatasets(datasets)
    Database.Datasets = datasets
    if Dependecies and Dependecies.RecomputeAllDatasetDependencies then
        Dependecies.RecomputeAllDatasetDependencies()
    end

    return datasets
end

function Database.GetDatasetDisplayName(dataset)
    local name = dataset and dataset.name or nil
    if name == nil or name == "" then
        return "Unnamed Dataset"
    end

    return tostring(name)
end

function Database.GetDatasetGroupName(dataset)
    local groupName = dataset and dataset.groupName or nil
    if groupName == nil then
        return ""
    end

    return ensureString(groupName, "")
end

function Database.GetRulesetDisplayName(ruleset)
    local name = ruleset and ruleset.name or nil
    if name == nil or name == "" then
        return "Unnamed Ruleset"
    end

    return tostring(name)
end

function Database.ListRulesets()
    local root = Database.EnsureRulesets()
    local entries = {}

    for _, ruleset in pairs(root.rulesets or {}) do
        entries[#entries + 1] = normalizeRulesetRecord(ruleset, ruleset and ruleset.id, ruleset and ruleset.name)
    end

    table.sort(entries, function(left, right)
        local leftName = string.lower(Database.GetRulesetDisplayName(left))
        local rightName = string.lower(Database.GetRulesetDisplayName(right))
        if leftName == rightName then
            return tostring(left.id or "") < tostring(right.id or "")
        end

        return leftName < rightName
    end)

    return entries
end

function Database.GetRulesetByID(rulesetId)
    if rulesetId == nil or rulesetId == "" then
        return nil
    end

    local root = Database.EnsureRulesets()
    return root.rulesets and root.rulesets[tostring(rulesetId)] or nil
end

function Database.GetActiveRulesetId()
    local root = Database.EnsureRulesets()
    local activeRulesetId = resolveCharacterScopedActiveId(root, "activeByChar")
    return activeRulesetId
end

function Database.SetActiveRulesetId(rulesetId)
    local root = Database.EnsureRulesets()
    local previousRulesetId, characterKey = resolveCharacterScopedActiveId(root, "activeByChar")

    if rulesetId == nil or rulesetId == "" then
        root.activeByChar[characterKey] = nil
        if previousRulesetId ~= nil then
            notifyConfigurationChanged("active-ruleset")
        end
        return nil
    end

    local ruleset = Database.GetRulesetByID(rulesetId)
    if not ruleset then
        return nil
    end

    root.activeByChar[characterKey] = ruleset.id
    if previousRulesetId ~= ruleset.id then
        notifyConfigurationChanged("active-ruleset")
    end
    return ruleset.id
end

function Database.GetActiveRuleset()
    local rulesetId = Database.GetActiveRulesetId()
    if not rulesetId then
        return nil
    end

    return Database.GetRulesetByID(rulesetId)
end

function Database.CreateRuleset(name)
    local root = Database.EnsureRulesets()
    local rulesetId = nextRulesetId(root)
    local ruleset = normalizeRulesetRecord({
        id = rulesetId,
        name = name ~= nil and tostring(name) or "New Ruleset",
        description = "",
        authorName = getCharacterDisplayName(),
        tagState = "standard",
        rules = {},
    }, rulesetId, name)

    root.rulesets[rulesetId] = ruleset
    return ruleset
end

function Database.ExportRuleset(rulesetId)
    local ruleset = Database.GetRulesetByID(rulesetId)
    if not ruleset then
        return nil
    end

    local payload = {
        format = "rpe-ruleset",
        version = 2,
        ruleset = normalizeRulesetRecordPreservingExtras(ruleset, ruleset.id, ruleset.name),
    }

    return "RPE_RULESET_V2\n" .. serializeLuaValue(payload)
end

function Database.ImportRuleset(text)
    local normalizedText = ensureString(text, "")
    normalizedText = normalizedText:gsub("^%s+", ""):gsub("%s+$", "")
    if normalizedText == "" then
        return nil, "Import text is empty."
    end

    local body = normalizedText
    local header = "RPE_RULESET_V2"
    if startsWith(body, header) then
        body = body:sub(#header + 1)
        if startsWith(body, "\r\n") then
            body = body:sub(3)
        elseif startsWith(body, "\n") or startsWith(body, "\r") then
            body = body:sub(2)
        end
    end

    local decoded, decodeError = deserializeLuaValue(body)
    if type(decoded) ~= "table" then
        return nil, decodeError or "Import text did not decode to a ruleset payload."
    end

    local payloadRuleset = decoded
    if decoded.format ~= nil or decoded.version ~= nil or decoded.ruleset ~= nil then
        if decoded.format ~= "rpe-ruleset" or tonumber(decoded.version) ~= 2 or type(decoded.ruleset) ~= "table" then
            return nil, "Import text is not a supported ruleset export."
        end

        payloadRuleset = decoded.ruleset
    end

    local root = Database.EnsureRulesets()
    local existingRulesets = {}
    for rulesetId, ruleset in pairs(root.rulesets or {}) do
        existingRulesets[tostring(rulesetId)] = ruleset
    end

    local imported = normalizeRulesetRecordPreservingExtras(payloadRuleset, payloadRuleset.id, payloadRuleset.name)
    if imported.id == "" then
        imported.id = nextRulesetId(root)
    elseif existingRulesets[imported.id] ~= nil then
        imported.id = nextRulesetId(root)
    end

    imported = normalizeRulesetRecordPreservingExtras(imported, imported.id, imported.name)
    existingRulesets[imported.id] = imported
    root.rulesets = existingRulesets
    notifyConfigurationChanged("ruleset-import")

    return imported
end

function Database.DeleteRuleset(rulesetId)
    local ruleset = Database.GetRulesetByID(rulesetId)
    if not ruleset then
        return false
    end

    local root = Database.EnsureRulesets()
    root.rulesets[ruleset.id] = nil

    for characterKey, activeRulesetId in pairs(root.activeByChar or {}) do
        if activeRulesetId == ruleset.id then
            root.activeByChar[characterKey] = nil
        end
    end

    notifyConfigurationChanged("ruleset-delete")

    return true
end

function Database.RenameRuleset(rulesetId, name)
    local ruleset = Database.GetRulesetByID(rulesetId)
    if not ruleset then
        return nil
    end

    ruleset.name = normalizeDatasetName(name)
    notifyConfigurationChanged("ruleset-rename")
    return ruleset
end

function Database.UpdateRulesetMetadata(rulesetId, metadata)
    local ruleset = Database.GetRulesetByID(rulesetId)
    if not ruleset then
        return nil
    end

    local values = ensureTable(metadata)

    if values.description ~= nil then
        ruleset.description = ensureString(values.description, "")
    end
    if values.tagState ~= nil then
        ruleset.tagState = normalizeDatasetState(values.tagState, { "standard", "short-term", "long-term" }, ruleset.tagState or "standard")
    end
    if values.rules ~= nil then
        ruleset.rules = ensureTable(values.rules)
    end

    notifyConfigurationChanged("ruleset-update")

    return ruleset
end

function Database.ListDatasets()
    local root = Database.EnsureDatasets()
    local entries = {}

    for _, dataset in pairs(root.datasets or {}) do
        entries[#entries + 1] = normalizeDatasetRecord(dataset, dataset and dataset.id, dataset and dataset.name)
    end

    table.sort(entries, function(left, right)
        local leftGroup = string.lower(Database.GetDatasetGroupName(left))
        local rightGroup = string.lower(Database.GetDatasetGroupName(right))
        if leftGroup ~= rightGroup then
            if leftGroup == "" then
                return true
            end
            if rightGroup == "" then
                return false
            end

            return leftGroup < rightGroup
        end

        local leftTypeOrder = DATASET_TYPE_SORT_ORDER[ensureString(left and left.datasetType, "general")] or DATASET_TYPE_SORT_ORDER.general
        local rightTypeOrder = DATASET_TYPE_SORT_ORDER[ensureString(right and right.datasetType, "general")] or DATASET_TYPE_SORT_ORDER.general
        if leftTypeOrder ~= rightTypeOrder then
            return leftTypeOrder < rightTypeOrder
        end

        local leftName = string.lower(Database.GetDatasetDisplayName(left))
        local rightName = string.lower(Database.GetDatasetDisplayName(right))
        if leftName == rightName then
            return tostring(left.id or "") < tostring(right.id or "")
        end

        return leftName < rightName
    end)

    return entries
end

function Database.GetDatasetByID(datasetId)
    if datasetId == nil or datasetId == "" then
        return nil
    end

    local root = Database.EnsureDatasets()
    return root.datasets and root.datasets[tostring(datasetId)] or nil
end

function Database.ResolveModelFilePath(displayId, fileDataId)
    local provider = getModelDataProvider()
    local tableData = provider and provider.GetTable and provider:GetTable() or provider
    if type(tableData) ~= "table" then
        return nil
    end

    local displayKey = tonumber(displayId)
    if displayKey and type(tableData[displayKey]) == "table" then
        local entry = tableData[displayKey]
        return entry.FilePath or entry.filePath or nil
    end

    local targetFileDataId = tonumber(fileDataId)
    if not targetFileDataId then
        return nil
    end

    for _, entry in pairs(tableData) do
        local currentFileDataId = type(entry) == "table" and tonumber(entry.FileDataID or entry.fileDataID) or nil
        if currentFileDataId and currentFileDataId == targetFileDataId then
            return entry.FilePath or entry.filePath or nil
        end
    end

    return nil
end

function Database.GetActiveDatasetId()
    local root = Database.EnsureDatasets()
    local activeDatasetId = resolveCharacterScopedActiveId(root, "activeByChar")
    return activeDatasetId
end

function Database.SetActiveDatasetId(datasetId)
    local root = Database.EnsureDatasets()
    local _, characterKey = resolveCharacterScopedActiveId(root, "activeByChar")

    if datasetId == nil or datasetId == "" then
        root.activeByChar[characterKey] = nil
        return nil
    end

    local dataset = Database.GetDatasetByID(datasetId)
    if not dataset then
        return nil
    end

    root.activeByChar[characterKey] = dataset.id
    return dataset.id
end

function Database.ListActivatedDatasetIds()
    local root = Database.EnsureDatasets()
    return normalizeActivatedDatasets(root)
end

function Database.IsDatasetActivated(datasetId)
    local dataset = Database.GetDatasetByID(datasetId)
    if not dataset then
        return false
    end

    local activated = Database.ListActivatedDatasetIds()
    for index = 1, #activated do
        if activated[index] == dataset.id then
            return true
        end
    end

    return false
end

function Database.SetDatasetActivated(datasetId, isActivated)
    local normalizedId = ensureString(datasetId, "")
    if normalizedId == "" then
        return false
    end

    local root = Database.EnsureDatasets()
    local activated = normalizeActivatedDatasets(root)
    local existingIndex = nil

    for index = 1, #activated do
        if activated[index] == normalizedId then
            existingIndex = index
            break
        end
    end

    if isActivated == true then
        if root.datasets[normalizedId] == nil then
            return false
        end

        if existingIndex == nil then
            activated[#activated + 1] = normalizedId
            notifyConfigurationChanged("dataset-activation")
        end
        return true
    end

    if existingIndex ~= nil then
        table.remove(activated, existingIndex)
        notifyConfigurationChanged("dataset-activation")
    end

    return true
end

function Database.ToggleDatasetActivated(datasetId)
    local active = Database.IsDatasetActivated(datasetId)
    if not Database.SetDatasetActivated(datasetId, not active) then
        return nil
    end

    return not active
end

function Database.GetActiveDataset()
    local datasetId = Database.GetActiveDatasetId()
    if not datasetId then
        return nil
    end

    return Database.GetDatasetByID(datasetId)
end

function Database.CreateDataset(name)
    local root = Database.EnsureDatasets()
    local datasetId = nextDatasetId(root)
    local dataset = normalizeDatasetRecord({
        id = datasetId,
        name = name ~= nil and tostring(name) or "New Dataset",
        groupName = "",
        description = "",
        authorName = getCharacterDisplayName(),
        datasetType = "general",
        dependencies = {},
        units = {},
        mounts = {},
        pets = {},
        items = {},
        spells = {},
        traits = {},
        skills = {},
        stats = {},
        resources = {},
        races = {},
        classes = {},
        itemSlots = {},
        weaponTypes = {},
        damageSchools = {},
        loot = {},
        recipes = {},
        auras = {},
        interactions = {},
        achievements = {},
        guildSettings = {},
        currencies = {},
    }, datasetId, name)

    root.datasets[datasetId] = dataset
    return dataset
end

function Database.ExportDataset(datasetId)
    local dataset = Database.GetDatasetByID(datasetId)
    if not dataset then
        return nil
    end

    local payload = {
        format = "rpe-dataset",
        version = 1,
        dataset = normalizeDatasetRecord(deepCopy(dataset), dataset.id, dataset.name),
    }

    return "RPE_DATASET_V1\n" .. serializeLuaValue(payload)
end

function Database.ExportDatasetEntry(datasetId, collectionKey, entryIdOrIndex)
    local dataset = Database.GetDatasetByID(datasetId)
    local definition = DATASET_ENTRY_DEFINITIONS[collectionKey]
    if not dataset or not definition then
        return nil
    end

    local entry = findDatasetEntry(dataset, collectionKey, entryIdOrIndex)
    if type(entry) ~= "table" then
        return nil
    end

    local payload = {
        format = "rpe-dataset-entry",
        version = 1,
        collectionKey = collectionKey,
        datasetId = dataset.id,
        entry = normalizeDatasetEntryRecord(dataset, collectionKey, entry, entry.id),
    }

    return "RPE_DATASET_ENTRY_V1\n" .. serializeLuaValue(payload)
end

function Database.ImportDataset(text)
    local normalizedText = ensureString(text, "")
    normalizedText = normalizedText:gsub("^%s+", ""):gsub("%s+$", "")
    if normalizedText == "" then
        return nil, "Import text is empty."
    end

    local body = normalizedText
    local header = "RPE_DATASET_V1"
    if startsWith(body, header) then
        body = body:sub(#header + 1)
        if startsWith(body, "\r\n") then
            body = body:sub(3)
        elseif startsWith(body, "\n") or startsWith(body, "\r") then
            body = body:sub(2)
        end
    end

    local decoded, decodeError = deserializeLuaValue(body)
    if type(decoded) ~= "table" then
        return nil, decodeError or "Import text did not decode to a dataset payload."
    end

    local payloadDataset = decoded
    if decoded.format ~= nil or decoded.version ~= nil or decoded.dataset ~= nil then
        if decoded.format ~= "rpe-dataset" or tonumber(decoded.version) ~= 1 or type(decoded.dataset) ~= "table" then
            return nil, "Import text is not a supported dataset export."
        end

        payloadDataset = decoded.dataset
    end

    local root = Database.EnsureDatasets()
    local existingDatasets = {}
    for datasetId, dataset in pairs(root.datasets or {}) do
        existingDatasets[tostring(datasetId)] = dataset
    end
    local imported = normalizeDatasetRecord(deepCopy(payloadDataset), payloadDataset.id, payloadDataset.name)
    local originalDatasetId = ensureString(imported.id, "")

    if imported.id == "" then
        imported.id = nextDatasetId(root)
    elseif existingDatasets[imported.id] ~= nil then
        imported.id = nextDatasetId(root)
        rewriteDatasetRefs(imported, originalDatasetId, imported.id)
    end

    imported = normalizeDatasetRecord(imported, imported.id, imported.name)
    existingDatasets[imported.id] = imported
    root.datasets = existingDatasets

    if Dependecies and Dependecies.RecomputeDatasetDependencies then
        Dependecies.RecomputeDatasetDependencies(imported.id)
    end
    if Dependecies and Dependecies.RecomputeAllDatasetDependencies then
        Dependecies.RecomputeAllDatasetDependencies()
    end

    notifyConfigurationChanged("dataset-import")

    return imported
end

function Database.ImportDatasetEntry(datasetId, collectionKey, text)
    local dataset = Database.GetDatasetByID(datasetId)
    local definition = DATASET_ENTRY_DEFINITIONS[collectionKey]
    if not dataset or not definition then
        return nil, "Dataset entry import is unavailable."
    end

    local normalizedText = ensureString(text, "")
    normalizedText = normalizedText:gsub("^%s+", ""):gsub("%s+$", "")
    if normalizedText == "" then
        return nil, "Import text is empty."
    end

    local body = normalizedText
    local header = "RPE_DATASET_ENTRY_V1"
    if startsWith(body, header) then
        body = body:sub(#header + 1)
        if startsWith(body, "\r\n") then
            body = body:sub(3)
        elseif startsWith(body, "\n") or startsWith(body, "\r") then
            body = body:sub(2)
        end
    end

    local decoded, decodeError = deserializeLuaValue(body)
    if type(decoded) ~= "table" then
        return nil, decodeError or "Import text did not decode to a dataset entry payload."
    end

    local payloadCollectionKey = collectionKey
    local payloadEntry = decoded
    if decoded.format ~= nil or decoded.version ~= nil or decoded.entry ~= nil or decoded.collectionKey ~= nil then
        if decoded.format ~= "rpe-dataset-entry"
            or tonumber(decoded.version) ~= 1
            or type(decoded.entry) ~= "table"
        then
            return nil, "Import text is not a supported dataset entry export."
        end

        payloadCollectionKey = ensureString(decoded.collectionKey, "")
        payloadEntry = decoded.entry
    end

    if payloadCollectionKey ~= collectionKey then
        return nil, ("Import text contains a %s entry, not a %s entry."):format(
            payloadCollectionKey ~= "" and payloadCollectionKey or "different",
            collectionKey
        )
    end

    dataset[collectionKey] = ensureTable(dataset[collectionKey])
    local entries = dataset[collectionKey]
    local importedId = ensureString(payloadEntry.id, "")
    if definition.assignsId then
        if importedId == "" or findDatasetEntry(dataset, collectionKey, importedId) ~= nil then
            importedId = nextDatasetEntryId(entries, collectionKey, definition)
        end
    end

    local normalizedEntry = normalizeDatasetEntryRecord(dataset, collectionKey, payloadEntry, importedId)
    if type(normalizedEntry) ~= "table" then
        return nil, "Import text did not produce a valid dataset entry."
    end

    entries[#entries + 1] = normalizedEntry
    Database.NotifyDatasetEntryChanged(dataset.id, collectionKey)

    return normalizedEntry, #entries
end

function Database.DeleteDataset(datasetId)
    local dataset = Database.GetDatasetByID(datasetId)
    if not dataset then
        return false
    end

    local root = Database.EnsureDatasets()
    Database.SetDatasetActivated(dataset.id, false)
    root.datasets[dataset.id] = nil
    if Dependecies and Dependecies.HandleDatasetDeleted then
        Dependecies.HandleDatasetDeleted(dataset.id)
    end

    for characterKey, activeDatasetId in pairs(root.activeByChar or {}) do
        if activeDatasetId == dataset.id then
            root.activeByChar[characterKey] = nil
        end
    end

    notifyConfigurationChanged("dataset-delete")

    return true
end

function Database.RenameDataset(datasetId, name)
    local dataset = Database.GetDatasetByID(datasetId)
    if not dataset then
        return nil
    end

    dataset.name = normalizeDatasetName(name)
    notifyConfigurationChanged("dataset-rename")
    return dataset
end

function Database.UpdateDatasetMetadata(datasetId, metadata)
    local dataset = Database.GetDatasetByID(datasetId)
    if not dataset then
        return nil
    end

    local values = ensureTable(metadata)

    if values.description ~= nil then
        dataset.description = ensureString(values.description, "")
    end
    if values.groupName ~= nil then
        dataset.groupName = ensureString(values.groupName, "")
    end
    if values.datasetType ~= nil then
        dataset.datasetType = normalizeDatasetState(values.datasetType, DATASET_TYPE_VALUES, dataset.datasetType or "general")
    end

    notifyConfigurationChanged("dataset-update")

    return dataset
end

function Database.NotifyDatasetEntryChanged(datasetId, collectionKey, options)
    local dataset = Database.GetDatasetByID(datasetId)
    if not dataset then
        return nil
    end

    if (collectionKey == "units"
            or collectionKey == "mounts"
            or collectionKey == "stats"
            or collectionKey == "resources"
            or collectionKey == "items"
            or collectionKey == "spells"
            or collectionKey == "traits"
            or collectionKey == "skills"
            or collectionKey == "races"
            or collectionKey == "classes"
            or collectionKey == "itemSlots"
            or collectionKey == "weaponTypes"
            or collectionKey == "damageSchools"
            or collectionKey == "auras"
            or collectionKey == "achievements"
            or collectionKey == "guildSettings")
        and Dependecies and Dependecies.RecomputeDatasetDependencies then
        Dependecies.RecomputeDatasetDependencies(datasetId)
    end

    local deferConfigurationChanged = type(options) == "table" and options.deferConfigurationChanged == true
    local client = Addon.Client or nil
    if deferConfigurationChanged and client and type(client.QueueLocalConfigurationRefresh) == "function" then
        markConfigurationChanged()
        client:QueueLocalConfigurationRefresh("dataset-entry")
    else
        notifyConfigurationChanged("dataset-entry")
    end

    return dataset
end

function Database.CreateDatasetEntry(datasetId, collectionKey)
    local dataset = Database.GetDatasetByID(datasetId)
    local definition = DATASET_ENTRY_DEFINITIONS[collectionKey]
    if not dataset or not definition then
        return nil
    end

    dataset[collectionKey] = ensureTable(dataset[collectionKey])
    local entries = dataset[collectionKey]
    local entryId = definition.assignsId and nextDatasetEntryId(entries, collectionKey, definition) or nil
    local entry = createDatasetEntryRecord(dataset, collectionKey, entryId)

    entries[#entries + 1] = entry
    Database.NotifyDatasetEntryChanged(dataset.id, collectionKey)
    return entry
end

function Database.CloneDatasetEntry(datasetId, collectionKey, entryIndex)
    local dataset = Database.GetDatasetByID(datasetId)
    local definition = DATASET_ENTRY_DEFINITIONS[collectionKey]
    local index = tonumber(entryIndex)
    if not dataset or not definition or not index then
        return nil
    end

    dataset[collectionKey] = ensureTable(dataset[collectionKey])
    local entries = dataset[collectionKey]
    local source = entries[index]
    if type(source) ~= "table" then
        return nil
    end

    local clone = deepCopy(source)
    if definition.assignsId then
        clone.id = nextDatasetEntryId(entries, collectionKey, definition)
    end
    clone.name = ensureString(clone.name, "")
    if clone.name == "" then
        clone.name = ("New %s"):format(definition.singular or "Entry")
    else
        clone.name = clone.name .. " Copy"
    end

    entries[#entries + 1] = clone
    Database.NotifyDatasetEntryChanged(dataset.id, collectionKey)
    return clone, #entries
end

function Database.DeleteDatasetEntry(datasetId, collectionKey, entryIndex)
    local dataset = Database.GetDatasetByID(datasetId)
    local definition = DATASET_ENTRY_DEFINITIONS[collectionKey]
    local index = tonumber(entryIndex)
    if not dataset or not definition or not index then
        return false
    end

    dataset[collectionKey] = ensureTable(dataset[collectionKey])
    local entries = dataset[collectionKey]
    if entries[index] == nil then
        return false
    end

    local removedEntry = entries[index]
    table.remove(entries, index)
    if Dependecies and Dependecies.HandleDatasetEntryDeleted then
        Dependecies.HandleDatasetEntryDeleted(dataset.id, collectionKey, removedEntry)
    end
    Database.NotifyDatasetEntryChanged(dataset.id, collectionKey)
    return true
end

function Database.EnsureGlobalSettings()
    Database.GlobalSettings = ensureSection("RPEngineGlobalSettingsDB", SCHEMA.globalSettings, {
        settings = {},
    })

    return Database.GlobalSettings
end

function Database.GetGlobalSetting(key, defaultValue)
    local normalizedKey = ensureString(key, "")
    if normalizedKey == "" then
        return deepCopy(defaultValue)
    end

    local globalSettings = Database.EnsureGlobalSettings()
    local settings = ensureTable(globalSettings and globalSettings.settings)
    globalSettings.settings = settings

    if settings[normalizedKey] == nil then
        return deepCopy(defaultValue)
    end

    return deepCopy(settings[normalizedKey])
end

function Database.SetGlobalSetting(key, value)
    local normalizedKey = ensureString(key, "")
    if normalizedKey == "" then
        return nil
    end

    local globalSettings = Database.EnsureGlobalSettings()
    local settings = ensureTable(globalSettings and globalSettings.settings)
    globalSettings.settings = settings
    settings[normalizedKey] = deepCopy(value)
    return settings[normalizedKey]
end

function Database.Initialize()
    Database.EnsureProfiles()
    Database.EnsureRulesets()
    Database.EnsureDatasets()
    Database.EnsureGlobalSettings()

    return Database
end

Database.Initialize()

local initializer = CreateFrame and CreateFrame("Frame")

if initializer then
    initializer:RegisterEvent("ADDON_LOADED")
    initializer:SetScript("OnEvent", function(_, event, loadedAddonName)
        if event ~= "ADDON_LOADED" then
            return
        end

        if loadedAddonName ~= addonName then
            return
        end

        Database.Initialize()
    end)
end
