local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}
Addon.Internal.Comms.Serialization = Addon.Internal.Comms.Serialization or {}
Addon.Utils = Addon.Utils or {}

local Common = Addon.Utils.Common or {}
local Serialization = Addon.Internal.Comms.Serialization

Serialization.PacketSeparator = Serialization.PacketSeparator or ":"
Serialization.ArgumentSeparator = Serialization.ArgumentSeparator or string.char(31)

local splitPreservingEmpty = Common.SplitPreservingEmpty

local function requireSeparator(separator, errorLevel)
    if type(separator) ~= "string" or separator == "" then
        error("Addon.Internal.Comms.Serialization requires a non-empty separator.", errorLevel or 3)
    end

    return separator
end

function Serialization:SerializeArguments(arguments, separator)
    local argumentSeparator = requireSeparator(separator or self.ArgumentSeparator, 3)
    local values = {}

    for index = 1, #(arguments or {}) do
        local value = arguments[index]
        if value == nil then
            values[#values + 1] = ""
        else
            values[#values + 1] = tostring(value)
        end
    end

    return table.concat(values, argumentSeparator)
end

function Serialization:DeserializeArguments(argumentsText, separator)
    local argumentSeparator = requireSeparator(separator or self.ArgumentSeparator, 3)
    return splitPreservingEmpty(argumentsText or "", argumentSeparator)
end

function Serialization:BuildChunkToken(partIndex, partCount)
    local chunkIndex = tonumber(partIndex)
    local chunkTotal = tonumber(partCount)

    if not chunkIndex or chunkIndex < 1 then
        return nil
    end

    if not chunkTotal or chunkTotal < 1 then
        return nil
    end

    if chunkTotal == 1 then
        return "1"
    end

    return ("%d/%d"):format(chunkIndex, chunkTotal)
end

function Serialization:ParseChunkToken(chunkToken)
    local token = tostring(chunkToken or "")
    if token == "" then
        return nil
    end

    local chunkParts = splitPreservingEmpty(token, "/", 2)
    if #chunkParts == 1 then
        local singleChunk = tonumber(chunkParts[1])
        if singleChunk == 1 then
            return 1, 1
        end

        return nil
    end

    local partIndex = tonumber(chunkParts[1])
    local partCount = tonumber(chunkParts[2])
    if not partIndex or not partCount then
        return nil
    end

    if partIndex < 1 or partCount < 2 or partIndex > partCount then
        return nil
    end

    return partIndex, partCount
end

function Serialization:SerializePacket(prefix, chunkToken, opcode, argumentsText)
    local packetSeparator = requireSeparator(self.PacketSeparator, 3)
    return table.concat({
        tostring(prefix or ""),
        tostring(chunkToken or ""),
        tostring(opcode or ""),
        tostring(argumentsText or ""),
    }, packetSeparator)
end

function Serialization:DeserializePacket(message)
    local packetSeparator = requireSeparator(self.PacketSeparator, 3)
    local parts = splitPreservingEmpty(message or "", packetSeparator, 4)
    local prefix = parts[1] or ""
    local chunkToken = parts[2] or ""
    local opcode = tonumber(parts[3])
    local argumentsText = parts[4]
    local partIndex, partCount = self:ParseChunkToken(chunkToken)

    if prefix == "" or not partIndex or not partCount or not opcode or argumentsText == nil then
        return nil
    end

    return {
        prefix = prefix,
        chunkToken = chunkToken,
        partIndex = partIndex,
        partCount = partCount,
        opcode = opcode,
        argumentsText = argumentsText,
    }
end
