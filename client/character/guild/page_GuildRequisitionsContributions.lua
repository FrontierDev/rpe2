local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Guild = Addon.Client.UI.Guild or {}

local Page = Addon.Client.UI.Guild.RequisitionsPage
local Guild = Addon.Client.Guild
if not Page or not Guild then return end

local OldPartitionRequisitions = Page.PartitionRequisitions

function Page:PartitionRequisitions()
    local shopRows, limitedRows = OldPartitionRequisitions(self)
    if type(Guild.GetGuildShopContributionRows) ~= "function" then
        return shopRows, limitedRows
    end

    local ok, contributed = pcall(Guild.GetGuildShopContributionRows, Guild)
    if not ok or type(contributed) ~= "table" then
        return shopRows, limitedRows
    end

    for index = 1, #contributed do
        local row = contributed[index]
        if type(row) == "table" and type(row.requisition) == "table" then
            shopRows[#shopRows + 1] = row.requisition
        end
    end

    return shopRows, limitedRows
end

return Page
