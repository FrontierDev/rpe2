local _, Addon = ...

Addon.Utils = Addon.Utils or {}

local Common = Addon.Utils.Common or {}
Addon.Utils.Common = Common

function Common.CopyTable(source)
    local target = {}

    for key, value in pairs(source or {}) do
        target[key] = value
    end

    return target
end

function Common.InvokeCallback(callback, ...)
    if type(callback) == "function" then
        callback(...)
    end
end

function Common.GetNow()
    if GetServerTime then
        return GetServerTime()
    end

    if time then
        return time()
    end

    return 0
end

function Common.TrimForDebug(value, maxLength)
    local text = tostring(value or "")
    if string.len(text) <= maxLength then
        return text
    end

    return string.sub(text, 1, maxLength - 3) .. "..."
end

function Common.Clamp(value, minimum, maximum)
    local numeric = tonumber(value) or 0
    if minimum ~= nil and numeric < minimum then
        numeric = minimum
    end
    if maximum ~= nil and numeric > maximum then
        numeric = maximum
    end
    return numeric
end

function Common.Round(value)
    return math.floor((tonumber(value) or 0) + 0.5)
end

function Common.FormatCopper(self, copper)
    if copper == nil and type(self) ~= "table" then
        copper = self
    end

    local amount = math.max(0, math.floor(tonumber(copper) or 0))
    local gold = math.floor(amount / 10000)
    local silver = math.floor((amount % 10000) / 100)
    local copperOnly = amount % 100
    local parts = {}

    if gold > 0 then
        parts[#parts + 1] = gold .. "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"
    end

    if silver > 0 then
        parts[#parts + 1] = silver .. "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"
    end

    if copperOnly > 0 or #parts == 0 then
        parts[#parts + 1] = copperOnly .. "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
    end

    return table.concat(parts, " ")
end

function Common.NormalizePercentValue(value)
    local numeric = tonumber(value) or 0
    if numeric > 1 then
        numeric = numeric / 100
    end
    return Common.Clamp(numeric, 0, 1)
end

function Common.SplitPreservingEmpty(value, separator, limit)
    local result = {}

    if value == nil then
        return result
    end

    local text = tostring(value)
    local startIndex = 1
    local maxParts = type(limit) == "number" and math.max(1, math.floor(limit)) or nil

    while true do
        if maxParts and #result + 1 >= maxParts then
            result[#result + 1] = string.sub(text, startIndex)
            break
        end

        local separatorIndex = string.find(text, separator, startIndex, true)
        if not separatorIndex then
            result[#result + 1] = string.sub(text, startIndex)
            break
        end

        result[#result + 1] = string.sub(text, startIndex, separatorIndex - 1)
        startIndex = separatorIndex + #separator
    end

    return result
end

function Common.NormalizeName(name)
    if type(name) ~= "string" or name == "" then
        return ""
    end

    if Ambiguate then
        return Ambiguate(name, "none")
    end

    return name
end

function Common.GetPlayerName()
    if GetUnitName then
        local name = GetUnitName("player", true)
        if name and name ~= "" then
            return Common.NormalizeName(name)
        end
    end

    if UnitName then
        local name = UnitName("player")
        if name and name ~= "" then
            return Common.NormalizeName(name)
        end
    end

    return "player"
end

function Common.GetPlayerGuid()
    if UnitGUID then
        return UnitGUID("player") or ""
    end

    return ""
end

function Common.GetGroupType()
    if IsInRaid and IsInRaid() then
        return "RAID"
    end

    if IsInGroup and IsInGroup() then
        return "PARTY"
    end

    return nil
end

function Common.GetGroupMemberNames()
    local names = {}
    local seen = {}

    local function addName(name)
        local normalized = Common.NormalizeName(name)
        if normalized == "" or seen[normalized] then
            return
        end

        seen[normalized] = true
        names[#names + 1] = normalized
    end

    addName(Common.GetPlayerName())

    local groupType = Common.GetGroupType()
    if groupType == "RAID" then
        local memberCount = GetNumGroupMembers and GetNumGroupMembers() or 0
        for index = 1, memberCount do
            addName(GetUnitName and GetUnitName("raid" .. index, true))
        end
    elseif groupType == "PARTY" then
        local memberCount = GetNumSubgroupMembers and GetNumSubgroupMembers() or 0
        for index = 1, memberCount do
            addName(GetUnitName and GetUnitName("party" .. index, true))
        end
    end

    return names
end

function Common.IsEventActive()
    return Addon.Client.EventState ~= nil and Addon.Client.EventState.active == true
end
