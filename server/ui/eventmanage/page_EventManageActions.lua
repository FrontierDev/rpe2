local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Server.UI = Addon.Server.UI or {}

local ServerUI = Addon.Server.UI

ServerUI.EventManage = ServerUI.EventManage or {}
local EventManage = ServerUI.EventManage

function EventManage:BuildActionsPage(page)
    self.ActionsPage = self.ActionsPage or page
    return self.ActionsPage
end
