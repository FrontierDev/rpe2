local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local SetupWizard = Addon.Client.UI.SetupWizard

if type(SetupWizard) ~= "table" or SetupWizard._actionBarNonEmptyCategoriesInstalled == true then
    return true
end

local originalBuildActionBarSpellNavigationRows = SetupWizard.BuildActionBarSpellNavigationRows

if type(originalBuildActionBarSpellNavigationRows) == "function" then
    function SetupWizard:BuildActionBarSpellNavigationRows(...)
        local rows = originalBuildActionBarSpellNavigationRows(self, ...) or {}
        local filtered = {}

        for index = 1, #rows do
            local row = rows[index]
            if type(row) == "table"
                and (row.rowType ~= "category" or (tonumber(row.count) or 0) > 0)
            then
                filtered[#filtered + 1] = row
            end
        end

        return filtered
    end
end

SetupWizard._actionBarNonEmptyCategoriesInstalled = true
return true
