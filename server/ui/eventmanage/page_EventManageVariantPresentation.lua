local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Server.UI = Addon.Server.UI or {}

local Server = Addon.Server
local ServerUI = Addon.Server.UI
local EventManage = ServerUI.EventManage

if type(EventManage) ~= "table" then
    return
end

function EventManage:ResolveCurrentEventUnitForRow(rowData)
    local eventId = tonumber(rowData and rowData.eventID) or 0
    if eventId <= 0 then
        return rowData and rowData.sourceUnit or nil
    end

    local eventState = type(Server.GetEditableEventState) == "function" and Server:GetEditableEventState() or nil
    for index = 1, #((eventState and eventState.units) or {}) do
        local unit = eventState.units[index]
        if tonumber(unit and unit.eventID) == eventId then
            return unit
        end
    end

    return rowData and rowData.sourceUnit or nil
end

function EventManage:BindUnitsTableRowHandlers()
    if not (self.UnitsTable and self.UnitsTable.bodyScroll and self.UnitsTable.bodyScroll.rows) then
        return false
    end

    for index = 1, #self.UnitsTable.bodyScroll.rows do
        local row = self.UnitsTable.bodyScroll.rows[index]
        if row and row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(targetRow, button, rowData)
                if button == "RightButton" then
                    EventManage:ShowUnitsContextMenu(targetRow, rowData)
                elseif button == "LeftButton"
                    and rowData
                    and rowData.isPlayer ~= true
                    and ServerUI
                    and ServerUI.EventUnit
                    and ServerUI.EventUnit.OpenForView
                then
                    ServerUI.EventUnit:OpenForView(EventManage:ResolveCurrentEventUnitForRow(rowData))
                end
            end)
        end
    end

    return true
end
