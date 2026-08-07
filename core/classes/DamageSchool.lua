local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local DamageSchool = {}
DamageSchool.__index = DamageSchool

function DamageSchool:New(data)
    return setmetatable({
        id = nil,
        name = "",
        description = "",
        icon = "",
        mitigationMode = "direct",
        mitigationStatRef = nil,
        mitigationCoefficient = 1,
        mitigationReferenceAmount = 0,
        mitigationReferencePercent = 0,
        tags = {},
    }, DamageSchool):Merge(data)
end

function DamageSchool:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    for key, value in pairs(data) do
        self[key] = value
    end

    return self
end

function DamageSchool:ToTable()
    return {
        id = self.id,
        name = self.name,
        description = self.description,
        icon = self.icon,
        mitigationMode = self.mitigationMode,
        mitigationStatRef = self.mitigationStatRef,
        mitigationCoefficient = self.mitigationCoefficient,
        mitigationReferenceAmount = tonumber(self.mitigationReferenceAmount) or 0,
        mitigationReferencePercent = tonumber(self.mitigationReferencePercent) or 0,
        tags = self.tags,
    }
end

function DamageSchool.FromTable(data)
    return DamageSchool:New(data)
end

Addon.Internal.Database.Classes.DamageSchool = DamageSchool
