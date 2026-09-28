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

function Serialization:BuildChunkToken(partIndex, partCount, messageId)
    local chunkIndex = tonumber(partIndex)
    local chunkTotal = tonumber(partCount)

    if not chunkIndex or chunkIndex < 1 then
        return nil
    end

    if not chunkTotal or chunkTotal < 1 then
        return nil
    end

    local sequence = chunkTotal == 1 and "1" or ("%d/%d"):format(chunkIndex, chunkTotal)
    local normalizedMessageId = tostring(messageId or "")
    if normalizedMessageId == "" then
        return sequence
    end

    -- The identifier is part of the packet header, rather than payload, so
    -- concurrent multipart messages from one sender/opcode cannot assemble
    -- into each other. It must not contain the packet separator.
    if string.find(normalizedMessageId, self.PacketSeparator or ":", 1, true)
        or string.find(normalizedMessageId, "~", 1, true)
    then
        return nil
    end
    return normalizedMessageId .. "~" .. sequence
end

function Serialization:ParseChunkToken(chunkToken)
    local token = tostring(chunkToken or "")
    if token == "" then
        return nil
    end

    local messageId = nil
    local sequence = token
    local separatorIndex = string.find(token, "~", 1, true)
    if separatorIndex then
        messageId = string.sub(token, 1, separatorIndex - 1)
        sequence = string.sub(token, separatorIndex + 1)
        if messageId == "" or sequence == "" then
            return nil
        end
    end

    local chunkParts = splitPreservingEmpty(sequence, "/", 2)
    if #chunkParts == 1 then
        local singleChunk = tonumber(chunkParts[1])
        if singleChunk == 1 then
            return 1, 1, messageId
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

    return partIndex, partCount, messageId
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
    local partIndex, partCount, messageId = self:ParseChunkToken(chunkToken)

    if prefix == "" or not partIndex or not partCount or not opcode or argumentsText == nil then
        return nil
    end

    return {
        prefix = prefix,
        chunkToken = chunkToken,
        partIndex = partIndex,
        partCount = partCount,
        messageId = messageId,
        opcode = opcode,
        argumentsText = argumentsText,
    }
end
