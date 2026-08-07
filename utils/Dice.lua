local _, Addon = ...

Addon.Utils = Addon.Utils or {}

local Common = Addon.Utils.Common or {}
local Dice = Addon.Utils.Dice or {}
Addon.Utils.Dice = Dice

function Dice.ParseExpression(expression, defaultCount, defaultSides)
    local text = string.lower(tostring(expression or ""))
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")

    local count = tonumber(defaultCount) or 1
    local sides = tonumber(defaultSides) or 20
    if text == "" then
        return count, sides
    end

    local parsedCount, parsedSides = string.match(text, "^(%d+)%s*d%s*(%d+)$")
    parsedCount = tonumber(parsedCount)
    parsedSides = tonumber(parsedSides)
    if parsedCount and parsedSides and parsedCount > 0 and parsedSides > 0 then
        return parsedCount, parsedSides
    end

    return count, sides
end

function Dice.RollRandom(context, minimum, maximum)
    local randomFn = type(context) == "table" and context.random or nil
    if type(randomFn) == "function" then
        local ok, value = pcall(randomFn, context, minimum, maximum)
        if ok and value ~= nil then
            return value
        end
    end

    if minimum ~= nil and maximum ~= nil and type(math.random) == "function" then
        return math.random(minimum, maximum)
    end

    if type(math.random) == "function" then
        return math.random()
    end

    return 0
end

function Dice.RollPercent(context)
    local value = tonumber(Dice.RollRandom(context))
    if value == nil then
        return 0
    end

    if value > 1 then
        return value
    end

    return value * 100
end

function Dice.RollVariance(context)
    if type(context) == "table" and context.variance ~= nil then
        return Common.Clamp(tonumber(context.variance) or 1, 0.9, 1.1)
    end

    local u1 = 1 - Common.Clamp(Dice.RollRandom(context), 0.000001, 0.999999)
    local u2 = Common.Clamp(Dice.RollRandom(context), 0.000001, 0.999999)
    local gaussian = math.sqrt(-2 * math.log(u1)) * math.sin(2 * math.pi * u2)
    return Common.Clamp(1 + (gaussian * 0.05), 0.9, 1.1)
end

function Dice.RollExpression(context, expression, defaultCount, defaultSides)
    local count, sides = Dice.ParseExpression(expression, defaultCount, defaultSides)
    local total = 0

    for _ = 1, count do
        total = total + (tonumber(Dice.RollRandom(context, 1, sides)) or 0)
    end

    return total
end

return Dice
